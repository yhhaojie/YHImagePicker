
##安装

#####添加插件
在工程主文件夹执行`cordova plugin add https://github.com/yhhaojie/YHImagePicker.git --save`

#####卸载插件
在工程主文件夹执行 `cordova plugin rm com.yhload.WKWebViewPlugin`

##使用


1. TS文件中声明`declare let cordova: any`；

2. 在需要使用插件的地方引入如下代码

```javascript
var retDic = {
	uuid: this.imgUuid
}
cordova.plugins.YHImagePicker.openPhotoLibrary(retDic, (successRet) => {
	this.imgPath = successRet.imgPath;
	this.imgUuid = successRet.imgUuid;

}, (errorRet) => { });

```

#####传入参数（json）

`uuid` 图片的唯一标识，可为空

#####传出参数（json）

`imgPath` 选择图片的地址

`imgUuid` 选择图片的额唯一标示，用于再次选择时标记已经选择过的照片

## 刷新页面

如果页面没有刷新，可添加如下代码

1. 引入 `import { ChangeDetectorRef } from '@angular/core';`

2. 让 Angualr 注入变量 `constructor(private cd: ChangeDetectorRef) {}`

3. 在需要刷新的地方执行

```javascript
this.cd.markForCheck();
this.cd.detectChanges();
```
