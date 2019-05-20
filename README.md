# vagrant-was-centos

ひさしぶりにtradtional WASのNetwork Deployment環境が必要になり、Vagrant上にサイレントインストールでインストールしたメモ。サイレントインストールは以下の3通りがあり、レスポンスファイルを作るのは面倒なので、コマンドモードが簡単。

- レスポンスファイルを使ったサイレントインストール
- コンソール・モード
- コマンド・モード

## 仮想マシンの準備

VMを2台Vagrantで起動する。1台でよい場合は`Vagrantfile`を修正すること。

### 前提ソフトウェア

- [Git](https://git-scm.com/)
- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)

```shell
brew install git
brew cask install virtualbox
brew cask install vagrant
```

VagrantはホストOSの`Vagrantfile`があるディレクトリーをVMの`/vagrant`にマウントするので、このディレクトリーを使って`Dockerfile`などファイルの受け渡しができるが、デフォルトではVM起動時にrsyncするだけなので、リアルタイムに同期するためには、VirtualBoxのGuest Additionsが必要で、これを自動でインストールしてくれる`vagrant-vbguest`プラグインを導入しておく。

```shell
vagrant plugin install vagrant-vbguest
```

（補足）
VirtulBox 6.0.8、Vagrant 2.2.4、vagrant-vbguest 0.17.2の組み合わせでは以下のIssueに該当するのかマウントが上手くいかなかった。

- https://github.com/dotless-de/vagrant-vbguest/issues/337

そのような場合はデフォルトのrsyncにしたほうがよい。`config.vm.synced_folder`をコメントアウトし、`config.vbguest.auto_update`を`false`にする。

```Vagrantfile
      # config.vm.synced_folder ".", "/vagrant", type:"virtualbox"

      if Vagrant.has_plugin?("vagrant-vbguest")
        config.vbguest.auto_update = false
      end
```

スナップショットをとれるように`sahara`プラグインを入れておくと便利。

```shell
vagrant plugin install sahara
```

### リポジトリのクローン

Vagrantfileを取得する。

```shell
# このgitリポジトリをクローン
git clone https://github.com/sotoiwa/vagrant-twas-centos
# クローンしたディレクトリーに入る
cd vagrant-twas-centos
# VM起動
vagrant up
```

### インストールパッケージの準備

ダウンロードしたWASのインストールイメージを`Vagrantfile`があるディレクトリーに置く。

```shell-session
$ ls -l *.zip
-rw-r--r--@ 1 sotoiwa  staff   559661094  5 20 13:48 9.0.0-WS-IHSPLG-FP011.zip
-rw-r--r--@ 1 sotoiwa  staff  1130998013  5 20 13:46 9.0.0-WS-WAS-FP011.zip
-rw-r--r--@ 1 sotoiwa  staff  1633871835  5 20 13:46 WAS_ND_V9.0_MP_ML.zip
-rw-r--r--@ 1 sotoiwa  staff   171926710  5 20 13:37 agent.installer.linux.gtk.x86_64_1.8.9004.20190423_2015.zip
-rw-r--r--@ 1 sotoiwa  staff   165819084  5 20 13:44 ibm-java-sdk-8.0-5.35-linux-x64-installmgr.zip
-rw-r--r--  1 sotoiwa  staff   992220534  5 20 15:50 sdk.repo.8030.java8.linux.zip
-rw-r--r--@ 1 sotoiwa  staff   205003961  5 20 13:28 was.repo.9000.ihs.zip
-rw-r--r--@ 1 sotoiwa  staff   318279547  5 20 13:29 was.repo.9000.plugins.zip
$
```

### 仮想マシンの起動

仮想マシンを起動してログインする。

```shell
vagrant up
vagrant ssh nod1
```

## WASのインストール

仮想マシン内でWASをインストールする。VMが2台の場合は両方のVMに対して実施。

### 準備

- [Linux システムのインストール準備](https://www.ibm.com/support/knowledgecenter/ja/SSAW57_9.0.0/com.ibm.websphere.installation.nd.doc/ae/tins_linuxsetup.html)
- [Red Hat Enterprise Linux 7 のインストール準備](https://www.ibm.com/support/knowledgecenter/ja/SSAW57_9.0.0/com.ibm.websphere.installation.nd.doc/ae/tins_linuxsetup_rhel7.html)

以下は全て`root`で実行。

```shell
sudo -i
```

```shell
echo 192.168.33.41 node1 >> /etc/hosts
echo 192.168.33.41 node1 >> /etc/hosts
```

```shell
ulimit -n 8192
echo "ulimit -n 8192" >> .bashrc
```

```shell
setenforce 0
sed -i '/^SELINUX=/c\SELINUX=disabled' /etc/selinux/config
```

```shell
yum install -y gtk2 libXtst xorg-x11-fonts-Type1 unzip
```

### リポジトリの準備

`/vagrant`ディレクトリーからzipファイルをコピーして`/work`ディレクトリーに展開する。

```shell
/vagrant/unzip_repo.sh
```

```bash:/vagrant/unziprepo.sh
#!/bin/bash

set -eu
set -o pipefail

function unzip_repo () {
    repo=$1
    filename=${!repo}
    mkdir -p /work/${repo}
    cd /work/${repo}
    cp /vagrant/${filename} .
    unzip -q ${filename}
}

IIM=agent.installer.linux.gtk.x86_64_1.8.9004.20190423_2015.zip
WAS=WAS_ND_V9.0_MP_ML.zip
JDK=sdk.repo.8030.java8.linux.zip
IHS=was.repo.9000.ihs.zip
PLG=was.repo.9000.plugins.zip
WAS_FP=9.0.0-WS-WAS-FP011.zip
JDK_FP=ibm-java-sdk-8.0-5.35-linux-x64-installmgr.zip
IHSPLG_FP=9.0.0-WS-IHSPLG-FP011.zip

unzip_repo IIM
unzip_repo WAS
unzip_repo JDK
unzip_repo IHS
unzip_repo PLG
unzip_repo WAS_FP
unzip_repo JDK_FP
unzip_repo IHSPLG_FP
```

### IIMのインストール

- [インストーラーの使用によるサイレントでの Installation Manager のインストールまたは更新](https://www.ibm.com/support/knowledgecenter/ja/SSDV2W_1.8.5/com.ibm.silentinstall12.doc/topics/t_silent_installIM_IMinst.html)

```shell
cd /work/IIM
./installc -acceptLicense
```

### WAS/IHS/プラグインのインストール

- [imcl コマンドの使用によるパッケージのインストール](https://www.ibm.com/support/knowledgecenter/ja/SSDV2W_1.8.5/com.ibm.cic.commandline.doc/topics/t_imcl_install.html)

```shell
# 確認
cd /opt/IBM/InstallationManager/eclipse/tools
./imcl listAvailablePackages \
  -repositories /work/WAS,/work/JDK,/work/IHS,/work/PLG,/work/WAS_FP,/work/JDK_FP,/work/IHSPLG_FP
# WAS
./imcl install com.ibm.websphere.ND.v90 com.ibm.java.jdk.v8 \
  -repositories /work/WAS,/work/JDK,/work/IHS,/work/PLG,/work/WAS_FP,/work/JDK_FP,/work/IHSPLG_FP \
  -installationDirectory /opt/IBM/WebSphere/AppServer \
  -installFixes all \
  -acceptLicense
# IHS
./imcl install com.ibm.websphere.IHS.v90 com.ibm.java.jdk.v8 \
  -repositories /work/WAS,/work/JDK,/work/IHS,/work/PLG,/work/WAS_FP,/work/JDK_FP,/work/IHSPLG_FP \
  -installationDirectory /opt/IBM/HTTPServer \
  -installFixes all \
  -acceptLicense
# プラグイン
./imcl install com.ibm.websphere.PLG.v90 com.ibm.java.jdk.v8 \
  -repositories /work/WAS,/work/JDK,/work/IHS,/work/PLG,/work/WAS_FP,/work/JDK_FP,/work/IHSPLG_FP \
  -installationDirectory /opt/IBM/WebSphere/Plugins \
  -installFixes all \
  -acceptLicense
```

### プロファイルの作成

- [manageprofiles コマンド](https://www.ibm.com/support/knowledgecenter/ja/SSAW57_9.0.0/com.ibm.websphere.installation.nd.doc/ae/rxml_manageprofiles.html)

デプロイメント・マネージャープロファイルを作成する（node1のみ）。

```shell
cd /opt/IBM/WebSphere/AppServer/bin
./manageprofiles.sh -create \
  -profileName Dmgr01 \
  -profilePath /opt/IBM/WebSphere/AppServer/profiles/Dmgr01 \
  -templatePath /opt/IBM/WebSphere/AppServer/profileTemplates/management \
  -serverType DEPLOYMENT_MANAGER \
  -enableAdminSecurity true \
  -adminUserName wasadmin \
  -adminPassword wasadmin
```

`INSTCONFPARTIALSUCCESS`になるが、ログをみると`createProfileShortCut2StartMenuMgmt.ant`が失敗しているので、デスクトップ環境がないためと推測。

デプロイメント・マネージャーを起動する（node1のみ）。

```shell
/opt/IBM/WebSphere/AppServer/profiles/Dmgr01/bin/startManager.sh
```

デプロイメント・マネージャーに接続するカスタムプロファイルを作成する。

```shell
./manageprofiles.sh -create \
  -profileName Custom01 \
  -profilePath /opt/IBM/WebSphere/AppServer/profiles/Custom01 \
  -templatePath /opt/IBM/WebSphere/AppServer/profileTemplates/managed \
  -dmgrHost localhost \
  -dmgrPort 8879 \
  -dmgrAdminUserName wasadmin \
  -dmgrAdminPassword wasadmin
```

こちらも`INSTCONFPARTIALSUCCESS`になるが、ログをみると`createProfileShortCut2StartMenuManaged.ant`が失敗しているので、デスクトップ環境がないためと推測。

### 管理コンソールへアクセス

- https://192.168.33.41:9043/ibm/console/logon.jsp

## Ansile

上記内容をAnsibleで実行するできるようにPlaybookにした。Vagrantで`ansible_local`というモジュールを使うこともできるが、ローカルのAnsibleを使用するようにしているため、Ansibleをインストールする。

```shell
brew install ansible
```

VMを起動してから、Playbookを実行。

```shell
vagrant up && ansible-playbook -i hosts site.yml
```

IPを直書きしていたり、Playbookに改善の余地はあるがとりあえず動いたのでOK。
