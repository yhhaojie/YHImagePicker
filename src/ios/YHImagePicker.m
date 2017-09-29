/********* YHImagePicker.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import <Photos/Photos.h>
#import "TZImagePickerController.h"

@interface YHImagePicker : CDVPlugin<TZImagePickerControllerDelegate> {
    // Member variables go here.
}

@property (nonatomic, copy) NSString *callbackId;
@property (nonatomic, copy) NSString *imageUuid;

- (void)openPhotoLibrary:(CDVInvokedUrlCommand*)command;

@end

@implementation YHImagePicker

#pragma mark - cordova 入口

- (void)openPhotoLibrary:(CDVInvokedUrlCommand*)command {
    self.callbackId = command.callbackId;
    [self.commandDelegate runInBackground:^{
    }];
    // 获取参数
    NSDictionary *dict  = [command argumentAtIndex:0 withDefault:nil];
    if (dict) {
        self.imageUuid = dict[@"imgUuid"];
    }
    [self imagePickerController];
}

#pragma mark - cordova 出口

- (void)successCallBack:(NSString*)imgPath imgUUid:(NSString*)imageUuid {
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:imgPath,@"imgPath",imageUuid,@"imgUuid", nil];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dic];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
}

- (void)failedCallBack {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
}

#pragma mark - custom

- (void)imagePickerController {
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
    imagePickerVc.allowTakePicture = NO; // 在内部显示拍照按钮
    imagePickerVc.allowPickingVideo = NO;
    imagePickerVc.allowPickingImage = YES;
    imagePickerVc.allowPickingOriginalPhoto = NO;
    imagePickerVc.allowPickingGif = NO;
    imagePickerVc.allowPickingMultipleVideo = NO; // 是否可以多选视频
    imagePickerVc.maxImagesCount = 1;
    imagePickerVc.imageUuid = self.imageUuid;// 记录上次选取的照片
    
    [self.viewController presentViewController:imagePickerVc animated:YES completion:nil];
}

#pragma mark - TZImagePickerControllerDelegate

- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    if (photos.count>0) {
        NSString *fileName = @"";
        
        id _asset = [assets objectAtIndex:0];
        fileName = [(PHAsset*)_asset valueForKey:@"filename"];
        self.imageUuid = [(PHAsset*)_asset valueForKey:@"uuid"];
        [self saveImgToFileSystem:[photos objectAtIndex:0] imgName:fileName];
    }
}

#pragma mark - 压缩 保存图片至沙盒

// 压缩 -> 保存 -> 返回路径
- (void)saveImgToFileSystem:(UIImage*)img imgName:(NSString*)imgName {
    // 1.压缩照片
    NSData *imgData = [self compressImage:img toByte:80*1024];
    NSLog(@"imgData.length:%ld",imgData.length);
    // 2.创建文件夹
    NSString *tempPath = NSTemporaryDirectory();
    NSFileManager *fileManager = [NSFileManager defaultManager];
    tempPath = [tempPath stringByAppendingPathComponent:@"yhImageFile/"];
    if(![fileManager fileExistsAtPath:tempPath]) {
        [fileManager createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    tempPath = [tempPath stringByAppendingPathComponent:imgName];
    
    // 3.保存文件
    BOOL ret = [imgData writeToFile:tempPath atomically:YES];
    if (ret) {
        [self successCallBack:tempPath imgUUid:self.imageUuid];
    } else {
        [self failedCallBack];
    }
}

- (NSData *)compressImage:(UIImage *)image toByte:(NSUInteger)maxLength {
    // Compress by quality
    CGFloat compression = 1;
    NSData *data = UIImageJPEGRepresentation(image, compression);
    if (data.length < maxLength) {
        return data;
    }
    CGFloat max = 1;
    CGFloat min = 0;
    for (int i = 0; i < 6; ++i) {
        compression = (max + min) / 2;
        data = UIImageJPEGRepresentation(image, compression);
        if (data.length < maxLength * 0.9) {
            min = compression;
        } else if (data.length > maxLength) {
            max = compression;
        } else {
            break;
        }
    }
    
    if (data.length < maxLength) {
         return data;
    }
    UIImage *resultImage = [UIImage imageWithData:data];
    // Compress by size
    NSUInteger lastDataLength = 0;
    while (data.length > maxLength && data.length != lastDataLength) {
        lastDataLength = data.length;
        CGFloat ratio = (CGFloat)maxLength / data.length;
        CGSize size = CGSizeMake((NSUInteger)(resultImage.size.width * sqrtf(ratio)),
                                 (NSUInteger)(resultImage.size.height * sqrtf(ratio))); // Use NSUInteger to prevent white blank
        UIGraphicsBeginImageContext(size);
        [resultImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
        resultImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        data = UIImageJPEGRepresentation(resultImage, compression);
    }
    return data;
}

@end
