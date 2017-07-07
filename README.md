# Orphe Hub

[ < README in English > ](/README_en.md)

Orphe HubはOrpheと他のアプリケーションを連携するためのハブとなるアプリケーションです。
現在開発途中のプロジェクトです。

## 現在実装されている機能

- OSCでセンサー値送信、Orpheの光を操作
- センサの値をMIDIのピッチベンド、コントロールチェンジの信号にマッピング


## 要件
- Xcode 8.3
- Swift 3.1
- Orphe-SDK-Swift-1.1.0 
- and your Orphe!

Orphe-SDK-Swift-1.1.0はFacebookグループの[Orphe Developers Community](https://www.facebook.com/groups/1757831034527899/)に参加いただくことでダウンロードすることが出来ます。


## 使用ライブラリ
- OSCKit

## 導入方法
- CocoaPodsの環境を設定した後 `pod update` でライブラリを導入。
- Orphe.framework 1.1.0を`TARGETS->General->Embedded Binaries`にドラッグ・アンド・ドロップする。

![unnamed](https://cloud.githubusercontent.com/assets/1403143/24959370/8eb19022-1fcd-11e7-8ce6-c505cea6c736.png)

- `Copy items if needed`をチェックしてFinishで完了。

![unnamed 1](https://cloud.githubusercontent.com/assets/1403143/24959394/9ce237f0-1fcd-11e7-91f1-36ee59c1b585.png)

- `.xcodeproj`ではなく`.xcworkspace`を開きます。
