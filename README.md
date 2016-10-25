本工程为基于高德地图iOS SDK进行封装，实现了定位轨迹记录并回放的功能
## 前述 ##
- [高德官网申请Key](http://lbs.amap.com/dev/#/).
- 阅读[开发指南](http://lbs.amap.com/api/ios-sdk/summary/).
- 工程基于iOS 3D地图SDK实现

## 功能描述 ##
基于3D地图SDK，可以记录定位点信息并保存，对保存的定位轨迹进行回放。保存的时候会进行轨迹纠偏操作，将定位点抓到道路上。