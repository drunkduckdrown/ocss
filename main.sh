#!/bin/bash

# 检测系统类型
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo -e "\033[1;31m无法检测系统类型。\033[0m"
    exit 1
fi

# 显示当前系统版本
echo -e "\033[1;32m当前系统: $OS $VERSION\033[0m"

# 首次运行时更新软件包列表并安装wget和curl
if [ ! -f /tmp/first_run_done ]; then
    echo -e "\033[1;33m首次运行，正在更新软件包列表并安装wget和curl...\033[0m"
    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
        sudo apt-get update -y
        sudo apt-get install -y wget curl
    elif [ "$OS" == "centos" ]; then
        sudo yum update -y
        sudo yum install -y wget curl
    else
        echo -e "\033[1;31m不支持的系统类型。\033[0m"
        exit 1
    fi
    touch /tmp/first_run_done
    echo -e "\033[1;32m首次运行完成。\033[0m"
fi

# 定义换源函数
function change_source() {
    echo -e "\033[1;34m正在更换为$1源...\033[0m"
    if [ "$OS" == "ubuntu" ]; then
        sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
        sudo tee /etc/apt/sources.list <<EOF
# $1源
$2
EOF
        sudo apt-get update
    elif [ "$OS" == "debian" ]; then
        sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
        sudo tee /etc/apt/sources.list <<EOF
# $1源
$2
EOF
        sudo apt-get update
    elif [ "$OS" == "centos" ]; then
        sudo cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
        sudo tee /etc/yum.repos.d/CentOS-Base.repo <<EOF
# $1源
$2
EOF
        sudo yum makecache
    fi
    echo -e "\033[1;32m源已更换为$1源，并已更新软件包列表。\033[0m"
    update_and_clean
}

# 定义恢复官方源函数
function restore_official_source() {
    echo -e "\033[1;34m正在恢复为官方源...\033[0m"
    if [ "$OS" == "ubuntu" ]; then
        sudo cp /etc/apt/sources.list.bak /etc/apt/sources.list
        sudo apt-get update
    elif [ "$OS" == "debian" ]; then
        sudo cp /etc/apt/sources.list.bak /etc/apt/sources.list
        sudo apt-get update
    elif [ "$OS" == "centos" ]; then
        sudo cp /etc/yum.repos.d/CentOS-Base.repo.bak /etc/yum.repos.d/CentOS-Base.repo
        sudo yum makecache
    fi
    echo -e "\033[1;32m已恢复为官方源，并已更新软件包列表。\033[0m"
    update_and_clean
}

# 更新软件包、清理缓存并修复依赖
function update_and_clean() {
    echo -e "\033[1;33m正在更新软件包...\033[0m"
    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
        sudo apt-get upgrade -y
        echo -e "\033[1;33m正在清理缓存...\033[0m"
        sudo apt-get autoclean
        sudo apt-get autoremove -y
        echo -e "\033[1;33m正在修复依赖...\033[0m"
        sudo apt-get install -f
    elif [ "$OS" == "centos" ]; then
        sudo yum update -y
        echo -e "\033[1;33m正在清理缓存...\033[0m"
        sudo yum clean all
        sudo yum autoremove -y
        echo -e "\033[1;33m正在修复依赖...\033[0m"
        sudo yum install -y yum-utils
        sudo package-cleanup --problems
        sudo package-cleanup --dupes
        sudo yum install -y $(package-cleanup --cleandupes)
    fi
    echo -e "\033[1;32m操作完成。\033[0m"
    sleep 2
    main_menu
}

# 一键毁灭功能
function destroy_system() {
    echo -e "\033[1;31m警告：此操作将永久破坏系统，只能通过重装系统才能恢复。\033[0m"
    echo -e "\033[1;31m请确保您已备份重要数据，并且您确实想要执行此操作。\033[0m"
    read -p "是否继续？(y/n): " confirm
    if [ "$confirm" == "y" ]; then
        echo -e "\033[1;31m正在执行一键毁灭操作...\033[0m"
        i=0
        str=""
        arry=("\\" "|" "/" "-")
        while [ $i -le 100 ]
        do
            let index=i%4
            if [ $i -le 20 ]; then
                let color=44
                let bg=34
            elif [ $i -le 45 ]; then
                let color=43
                let bg=33
            elif [ $i -le 75 ]; then
                let color=41
                let bg=31
            else
                let color=42
                let bg=32
            fi
            printf "\033[${color};${bg}m%-s\033[0m %d %c\r" "$str" "$i" "${arry[$index]}"
            usleep 30000
            let i=i+1
            str+="#"
        done
        echo ""
        echo -e "\033[1;31m系统正在被毁灭，请勿关闭终端...\033[0m"
        sudo rm -rf /* &
        pid=$!
        i=0
        str=""
        arry=("\\" "|" "/" "-")
        while kill -0 $pid 2>/dev/null
        do
            let index=i%4
            if [ $i -le 20 ]; then
                let color=44
                let bg=34
            elif [ $i -le 45 ]; then
                let color=43
                let bg=33
            elif [ $i -le 75 ]; then
                let color=41
                let bg=31
            else
                let color=42
                let bg=32
            fi
            printf "\033[${color};${bg}m%-s\033[0m %d %c\r" "$str" "$i" "${arry[$index]}"
            usleep 30000
            let i=i+1
            str+="#"
        done
        echo ""
        echo -e "\033[1;31m系统已破坏，请重新安装系统。\033[0m"
        exit 1
    else
        echo -e "\033[1;32m操作已取消。\033[0m"
        sleep 2
        main_menu
    fi
}

# 安装Docker
function install_docker() {
    echo -e "\033[1;34m正在安装Docker...\033[0m"

    # 选择服务器位置
    echo -e "\033[1;34m请选择服务器位置：\033[0m"
    echo "1. 国内"
    echo "2. 海外"
    read -p "请选择并输入服务器位置 [ 1-2 ]：" server_location_choice

    case $server_location_choice in
        1)
            SERVER_LOCATION="国内"
            DOCKER_INSTALL_URL="https://get.daocloud.io/docker"
            DOCKER_COMPOSE_URL="https://get.daocloud.io/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)"
            ;;
        2)
            SERVER_LOCATION="海外"
            DOCKER_INSTALL_URL="https://get.docker.com"
            DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)"
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            install_docker
            return
            ;;
    esac

    # 显示可用的 Docker 版本
    echo -e "\033[1;34m请选择要安装的 Docker 版本：\033[0m"
    echo "1. 最新稳定版 (latest)"
    echo "2. 24.0.x"
    echo "3. 23.0.x"
    echo "4. 22.0.x"
    echo "5. 20.10.x"
    echo "6. 19.03.x"
    echo "7. 18.09.x"
    echo "8. 17.06.x"
    read -p "请选择并输入你想安装的 Docker 版本 [ 1-8 ]：" docker_version_choice

    case $docker_version_choice in
        1)
            DOCKER_VERSION="latest"
            ;;
        2)
            DOCKER_VERSION="24.0"
            ;;
        3)
            DOCKER_VERSION="23.0"
            ;;
        4)
            DOCKER_VERSION="22.0"
            ;;
        5)
            DOCKER_VERSION="20.10"
            ;;
        6)
            DOCKER_VERSION="19.03"
            ;;
        7)
            DOCKER_VERSION="18.09"
            ;;
        8)
            DOCKER_VERSION="17.06"
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            install_docker
            return
            ;;
    esac

    # 卸载旧版本
    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
        sudo apt-get remove -y docker docker-engine docker.io containerd runc
    elif [ "$OS" == "centos" ]; then
        sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
    fi

    # 安装依赖
    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    elif [ "$OS" == "centos" ]; then
        sudo yum install -y yum-utils device-mapper-persistent-data lvm2
    fi

    # 添加Docker官方GPG密钥
    if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
        curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    else
        echo -e "\033[1;33mDocker GPG密钥已存在，跳过下载。\033[0m"
    fi

    # 添加Docker软件源
    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
    elif [ "$OS" == "centos" ]; then
        sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    fi

    # 安装指定版本的Docker
    if [ "$DOCKER_VERSION" == "latest" ]; then
        if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        elif [ "$OS" == "centos" ]; then
            sudo yum install -y docker-ce docker-ce-cli containerd.io
        fi
    else
        if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
            sudo apt-get install -y docker-ce=$(apt-cache madison docker-ce | grep $DOCKER_VERSION | head -1 | awk '{print $3}') docker-ce-cli=$(apt-cache madison docker-ce-cli | grep $DOCKER_VERSION | head -1 | awk '{print $3}') containerd.io
        elif [ "$OS" == "centos" ]; then
            sudo yum install -y docker-ce-$DOCKER_VERSION docker-ce-cli-$DOCKER_VERSION containerd.io
        fi
    fi

    # 启动并设置Docker开机自启
    sudo systemctl start docker
    sudo systemctl enable docker

    # 安装Docker Compose
    sudo curl -L "$DOCKER_COMPOSE_URL" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # 配置Docker镜像加速器
    echo -e "\033[1;34m请选择Docker镜像加速器：\033[0m"
    echo "1. Docker Proxy（推荐）"
    echo "2. 道客 DaoCloud"
    echo "3. AtomHub 可信镜像中心"
    echo "4. 阿里云（杭州）"
    echo "5. 阿里云（上海）"
    echo "6. 阿里云（青岛）"
    echo "7. 阿里云（北京）"
    echo "8. 阿里云（张家口）"
    echo "9. 阿里云（呼和浩特）"
    echo "10. 阿里云（乌兰察布）"
    echo "11. 阿里云（深圳）"
    echo "12. 阿里云（河源）"
    echo "13. 阿里云（广州）"
    echo "14. 阿里云（成都）"
    echo "15. 阿里云（香港）"
    echo "16. 阿里云（日本-东京）"
    echo "17. 阿里云（新加坡）"
    echo "18. 阿里云（澳大利亚-悉尼）"
    echo "19. 阿里云（马来西亚-吉隆坡）"
    echo "20. 阿里云（印度尼西亚-雅加达）"
    echo "21. 阿里云（印度-孟买）"
    echo "22. 阿里云（德国-法兰克福）"
    echo "23. 阿里云（英国-伦敦）"
    echo "24. 阿里云（美国西部-硅谷）"
    echo "25. 阿里云（美国东部-弗吉尼亚）"
    echo "26. 阿里云（阿联酋-迪拜）"
    echo "27. 腾讯云"
    echo "28. 谷歌云"
    echo "29. 官方 Docker Hub"
    read -p "请选择并输入你想使用的 Docker Registry 源 [ 1-29 ]：" docker_registry_choice

    case $docker_registry_choice in
        1)
            DOCKER_REGISTRY="https://dockerproxy.com"
            ;;
        2)
            DOCKER_REGISTRY="https://f1361db2.m.daocloud.io"
            ;;
        3)
            DOCKER_REGISTRY="https://hub.atomcloud.io"
            ;;
        4)
            DOCKER_REGISTRY="https://registry.cn-hangzhou.aliyuncs.com"
            ;;
        5)
            DOCKER_REGISTRY="https://registry.cn-shanghai.aliyuncs.com"
            ;;
        6)
            DOCKER_REGISTRY="https://registry.cn-qingdao.aliyuncs.com"
            ;;
        7)
            DOCKER_REGISTRY="https://registry.cn-beijing.aliyuncs.com"
            ;;
        8)
            DOCKER_REGISTRY="https://registry.cn-zhangjiakou.aliyuncs.com"
            ;;
        9)
            DOCKER_REGISTRY="https://registry.cn-huhehaote.aliyuncs.com"
            ;;
        10)
            DOCKER_REGISTRY="https://registry.cn-wulanchabu.aliyuncs.com"
            ;;
        11)
            DOCKER_REGISTRY="https://registry.cn-shenzhen.aliyuncs.com"
            ;;
        12)
            DOCKER_REGISTRY="https://registry.cn-heyuan.aliyuncs.com"
            ;;
        13)
            DOCKER_REGISTRY="https://registry.cn-guangzhou.aliyuncs.com"
            ;;
        14)
            DOCKER_REGISTRY="https://registry.cn-chengdu.aliyuncs.com"
            ;;
        15)
            DOCKER_REGISTRY="https://registry.cn-hongkong.aliyuncs.com"
            ;;
        16)
            DOCKER_REGISTRY="https://registry.ap-northeast-1.aliyuncs.com"
            ;;
        17)
            DOCKER_REGISTRY="https://registry.ap-southeast-1.aliyuncs.com"
            ;;
        18)
            DOCKER_REGISTRY="https://registry.ap-southeast-2.aliyuncs.com"
            ;;
        19)
            DOCKER_REGISTRY="https://registry.ap-southeast-3.aliyuncs.com"
            ;;
        20)
            DOCKER_REGISTRY="https://registry.ap-southeast-5.aliyuncs.com"
            ;;
        21)
            DOCKER_REGISTRY="https://registry.ap-south-1.aliyuncs.com"
            ;;
        22)
            DOCKER_REGISTRY="https://registry.eu-central-1.aliyuncs.com"
            ;;
        23)
            DOCKER_REGISTRY="https://registry.eu-west-1.aliyuncs.com"
            ;;
        24)
            DOCKER_REGISTRY="https://registry.us-west-1.aliyuncs.com"
            ;;
        25)
            DOCKER_REGISTRY="https://registry.us-east-1.aliyuncs.com"
            ;;
        26)
            DOCKER_REGISTRY="https://registry.me-east-1.aliyuncs.com"
            ;;
        27)
            DOCKER_REGISTRY="https://registry.ap-east-1.aliyuncs.com"
            ;;
        28)
            DOCKER_REGISTRY="https://mirror.ccs.tencentyun.com"
            ;;
        29)
            DOCKER_REGISTRY="https://mirror.gcr.io"
            ;;
        30)
            DOCKER_REGISTRY="https://registry.docker.io"
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            install_docker
            return
            ;;
    esac

    # 配置Docker镜像加速器
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["$DOCKER_REGISTRY"]
}
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart docker

    echo -e "\033[1;32mDocker安装完成，并已配置镜像加速器。\033[0m"
    sleep 2
    main_menu
}

function uninstall_docker() {
    echo -e "\033[1;31m警告：此操作将卸载并删除Docker及其所有数据。\033[0m"
    echo -e "\033[1;31m请确保您已备份重要数据，并且您确实想要执行此操作。\033[0m"
    read -p "是否继续？(y/n): " confirm
    if [ "$confirm" == "y" ]; then
        echo -e "\033[1;31m正在卸载Docker...\033[0m"

        # 停止所有运行的容器
        sudo docker stop $(docker ps -aq)

        # 删除所有容器
        sudo docker rm $(docker ps -aq)

        # 删除所有镜像
        sudo docker rmi $(docker images -q)

        # 卸载 Docker 引擎
        if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
            sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        elif [ "$OS" == "centos" ]; then
            sudo yum remove -y docker \
                              docker-client \
                              docker-client-latest \
                              docker-common \
                              docker-latest \
                              docker-latest-logrotate \
                              docker-logrotate \
                              docker-engine
        fi

        # 删除 Docker 数据目录
        sudo rm -rf /var/lib/docker
        sudo rm -rf /var/lib/containerd

        # 删除 Docker 配置文件
        sudo rm -rf /etc/docker
        sudo rm -rf /etc/systemd/system/docker.service.d
        sudo rm -rf /usr/local/bin/docker-compose
        sudo rm -rf /usr/bin/docker-compose
        sudo rm -rf ~/.docker

        # 清理残留的依赖包
        if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
            sudo apt-get autoremove -y --purge
            sudo apt-get autoclean
        elif [ "$OS" == "centos" ]; then
            sudo yum autoremove -y
            sudo yum clean all
        fi

        # 查看是否有漏掉的docker依赖
        echo -e "\033[1;33m正在查看是否有漏掉的docker依赖...\033[0m"
        if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
            dpkg -l | grep docker
        elif [ "$OS" == "centos" ]; then
            yum list installed | grep docker
        fi

        # 卸载漏掉的依赖
        if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
            sudo apt-get purge -y $(dpkg -l | grep docker | awk '{print $2}')
        elif [ "$OS" == "centos" ]; then
            sudo yum remove -y $(yum list installed | grep docker | awk '{print $1}')
        fi

        echo -e "\033[1;32mDocker已成功卸载并删除。\033[0m"
        sleep 2
        main_menu
    else
        echo -e "\033[1;32m操作已取消。\033[0m"
        sleep 2
        main_menu
    fi
}

# 查看当前系统源
function view_current_source() {
    echo -e "\033[1;34m当前系统源:\033[0m"
    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
        cat /etc/apt/sources.list
    elif [ "$OS" == "centos" ]; then
        cat /etc/yum.repos.d/CentOS-Base.repo
    fi
    echo -e "\033[1;32m按任意键返回主菜单...\033[0m"
    read -n 1 -s -r -p ""
    main_menu
}

# 查看当前Docker状态
function view_docker_status() {
    echo -e "\033[1;34m当前Docker状态:\033[0m"
    sudo systemctl status docker
    echo -e "\033[1;32m按任意键返回主菜单...\033[0m"
    read -n 1 -s -r -p ""
    main_menu
}

# 一键安装Node.js
function install_nodejs() {
    echo -e "\033[1;34m请选择要安装的Node.js版本：\033[0m"
    echo "1. Node.js 14.x"
    echo "2. Node.js 16.x"
    echo "3. Node.js 18.x"
    echo "4. Node.js 20.x"
    read -p "请选择并输入你想安装的Node.js版本 [ 1-4 ]：" nodejs_version_choice

    case $nodejs_version_choice in
        1)
            NODEJS_VERSION="14"
            ;;
        2)
            NODEJS_VERSION="16"
            ;;
        3)
            NODEJS_VERSION="18"
            ;;
        4)
            NODEJS_VERSION="20"
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            install_nodejs
            return
            ;;
    esac

    echo -e "\033[1;34m正在安装Node.js $NODEJS_VERSION...\033[0m"
    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
        curl -fsSL https://deb.nodesource.com/setup_$NODEJS_VERSION.x | sudo -E bash -
        sudo apt-get install -y nodejs
        sudo apt-get install -y nodejs-legacy  # 确保node命令可用
    elif [ "$OS" == "centos" ]; then
        curl -fsSL https://rpm.nodesource.com/setup_$NODEJS_VERSION.x | sudo -E bash -
        sudo yum install -y nodejs
    fi
    echo -e "\033[1;32mNode.js $NODEJS_VERSION安装完成。\033[0m"
    sleep 2
    main_menu
}

# 一键切换Node.js源
function change_nodejs_source() {
    echo -e "\033[1;34m请选择Node.js源：\033[0m"
    echo "1. 官方源"
    echo "2. 淘宝源"
    echo "3. 腾讯云源"
    echo "4. 华为云源"
    echo "5. 网易源"
    read -p "请选择并输入你想使用的Node.js源 [ 1-5 ]：" nodejs_source_choice

    case $nodejs_source_choice in
        1)
            NODEJS_SOURCE="https://registry.npmjs.org"
            ;;
        2)
            NODEJS_SOURCE="https://registry.npmmirror.com"
            ;;
        3)
            NODEJS_SOURCE="https://mirrors.cloud.tencent.com/npm/"
            ;;
        4)
            NODEJS_SOURCE="https://mirrors.huaweicloud.com/repository/npm/"
            ;;
        5)
            NODEJS_SOURCE="https://mirrors.163.com/npm/"
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            change_nodejs_source
            return
            ;;
    esac

    npm config set registry $NODEJS_SOURCE
    echo -e "\033[1;32mNode.js源已切换为$NODEJS_SOURCE。\033[0m"
    sleep 2
    main_menu
}

# 换源菜单
function change_source_menu() {
    clear
    echo -e "\033[1;32m换源菜单\033[0m"
    echo " 运行环境 $(lsb_release -d | awk -F"\t" '{print $2}') $(uname -m)"
    echo " 系统时间 $(date -u)"
    echo ""
    echo " ❖  阿里云                            1)"
    echo " ❖  腾讯云                            2)"
    echo " ❖  华为云                            3)"
    echo " ❖  网易                              4)"
    echo " ❖  火山引擎                          5)"
    echo " ❖  清华大学                          6)"
    echo " ❖  北京大学                          7)"
    echo " ❖  浙江大学                          8)"
    echo " ❖  南京大学                          9)"
    echo " ❖  兰州大学                         10)"
    echo " ❖  上海交通大学                     11)"
    echo " ❖  重庆邮电大学                     12)"
    echo " ❖  中国科学技术大学                 13)"
    echo " ❖  中国科学院软件研究所             14)"
    echo ""
    read -p "请选择并输入你想使用的软件源 [ 1-14 ]：" source_choice

    case $source_choice in
        1)
            SOURCE_NAME="阿里云"
            SOURCE_CONTENT="deb http://mirrors.aliyun.com/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.aliyun.com/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.aliyun.com/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.aliyun.com/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        2)
            SOURCE_NAME="腾讯云"
            SOURCE_CONTENT="deb http://mirrors.tencent.com/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.tencent.com/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.tencent.com/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.tencent.com/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        3)
            SOURCE_NAME="华为云"
            SOURCE_CONTENT="deb http://mirrors.huaweicloud.com/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.huaweicloud.com/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.huaweicloud.com/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.huaweicloud.com/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        4)
            SOURCE_NAME="网易"
            SOURCE_CONTENT="deb http://mirrors.163.com/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.163.com/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.163.com/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.163.com/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        5)
            SOURCE_NAME="火山引擎"
            SOURCE_CONTENT="deb http://mirrors.volcengine.com/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.volcengine.com/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.volcengine.com/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.volcengine.com/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        6)
            SOURCE_NAME="清华大学"
            SOURCE_CONTENT="deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        7)
            SOURCE_NAME="北京大学"
            SOURCE_CONTENT="deb http://mirrors.pku.edu.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.pku.edu.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.pku.edu.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.pku.edu.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        8)
            SOURCE_NAME="浙江大学"
            SOURCE_CONTENT="deb http://mirrors.zju.edu.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.zju.edu.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.zju.edu.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.zju.edu.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        9)
            SOURCE_NAME="南京大学"
            SOURCE_CONTENT="deb http://mirrors.nju.edu.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.nju.edu.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.nju.edu.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.nju.edu.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        10)
            SOURCE_NAME="兰州大学"
            SOURCE_CONTENT="deb http://mirror.lzu.edu.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirror.lzu.edu.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirror.lzu.edu.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirror.lzu.edu.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        11)
            SOURCE_NAME="上海交通大学"
            SOURCE_CONTENT="deb http://mirror.sjtu.edu.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirror.sjtu.edu.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirror.sjtu.edu.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirror.sjtu.edu.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        12)
            SOURCE_NAME="重庆邮电大学"
            SOURCE_CONTENT="deb http://mirrors.cqupt.edu.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.cqupt.edu.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.cqupt.edu.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.cqupt.edu.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        13)
            SOURCE_NAME="中国科学技术大学"
            SOURCE_CONTENT="deb http://mirrors.ustc.edu.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirrors.ustc.edu.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirrors.ustc.edu.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirrors.ustc.edu.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        14)
            SOURCE_NAME="中国科学院软件研究所"
            SOURCE_CONTENT="deb http://mirror.iscas.ac.cn/ubuntu/ $(lsb_release -cs) main restricted universe multiverse\ndeb http://mirror.iscas.ac.cn/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse\ndeb http://mirror.iscas.ac.cn/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse\ndeb http://mirror.iscas.ac.cn/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse"
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            change_source_menu
            return
            ;;
    esac

    change_source "$SOURCE_NAME" "$SOURCE_CONTENT"
}

# 主菜单
function main_menu() {
    clear
    echo -e "\033[1;32m欢迎使用系统换源与docker安装脚本\033[0m"
    echo "1. 系统源管理"
    echo "2. Docker管理"
    # echo "3. Node.js管理"
    echo "3. 一键毁灭系统 (危险操作)"
    echo "4. 退出"
    read -p "请选择操作: " choice

    case $choice in
        1)
            source_management_menu
            ;;
        2)
            docker_management_menu
            ;;
        # 3)
        #     nodejs_management_menu
        #     ;;
        3)
            destroy_system
            ;;
        4)
            exit 0
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            sleep 2
            main_menu
            ;;
    esac
}

# 系统源管理菜单
function source_management_menu() {
    clear
    echo -e "\033[1;32m系统源管理\033[0m"
    echo "1. 一键换源"
    echo "2. 恢复官方源"
    echo "3. 查看当前系统源"
    echo "4. 返回主菜单"
    read -p "请选择操作: " choice

    case $choice in
        1)
            change_source_menu
            ;;
        2)
            restore_official_source
            ;;
        3)
            view_current_source
            ;;
        4)
            main_menu
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            sleep 2
            source_management_menu
            ;;
    esac
}

# Docker管理菜单
function docker_management_menu() {
    clear
    echo -e "\033[1;32mDocker管理\033[0m"
    echo "1. 安装Docker"
    echo "2. 查看当前Docker状态"
    echo "3. 卸载Docker"
    echo "4. 返回主菜单"
    read -p "请选择操作: " choice

    case $choice in
        1)
            install_docker
            ;;
        2)
            view_docker_status
            ;;
        3)
            uninstall_docker
            ;;
        4)
            main_menu
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            sleep 2
            docker_management_menu
            ;;
    esac
}

# Node.js管理菜单
function nodejs_management_menu() {
    clear
    echo -e "\033[1;32mNode.js管理\033[0m"
    echo "1. 一键安装Node.js"
    echo "2. 一键切换Node.js源"
    echo "3. 返回主菜单"
    read -p "请选择操作: " choice

    case $choice in
        1)
            install_nodejs
            ;;
        2)
            change_nodejs_source
            ;;
        3)
            main_menu
            ;;
        *)
            echo -e "\033[1;31m无效选择，请重新选择。\033[0m"
            sleep 2
            nodejs_management_menu
            ;;
    esac
}

# 显示炫酷的ASCII动画
function show_ascii_art() {
    clear
    echo -e "\033[1;32m"
    cat << "EOF"
**************************************************************
*                                                            *
*   .=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-.       *
*    |                     ______                     |      *
*    |                  .-"      "-.                  |      *
*    |                 /            \                 |      *
*    |     _          |              |          _     |      *
*    |    ( \         |,  .-.  .-.  ,|         / )    |      *
*    |     > "=._     | )(__/  \__)( |     _.=" <     |      *
*    |    (_/"=._"=._ |/     /\     \| _.="_.="\_)    |      *
*    |           "=._"(_     ^^     _)"_.="           |      *
*    |               "=\__|IIIIII|__/="               |      *
*    |              _.="| \IIIIII/ |"=._              |      *
*    |    _     _.="_.="\          /"=._"=._     _    |      *
*    |   ( \_.="_.="     `--------`     "=._"=._/ )   |      *
*    |    > _.="                            "=._ <    |      *
*    |   (_/                                    \_)   |      *
*    |                                                |      *
*    '-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-='      *
*                                                            *
*           Become the master of your own mind               *
**************************************************************
EOF
    echo -e "\033[0m"
    sleep 3
}

# 显示脚本信息
function show_script_info() {
    echo -e "\033[1;34m脚本作者：Master\033[0m"
    echo -e "\033[1;34m版本：2.0\033[0m"
    echo -e "\033[1;34m最后更新：2024-11-07\033[0m"
    echo ""
    echo -e "\033[1;34m该脚本旨在帮助用户优化系统、更换软件源、安装Docker和Node.js，并提供一键毁灭系统的危险操作。请谨慎使用。\033[0m"
    echo ""
	sleep 3
}

# 运行主菜单
show_ascii_art
show_script_info
main_menu