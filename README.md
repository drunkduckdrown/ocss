# ocss(One-Click Source Switch)
一个Ubuntu,Centos,Debian,node.js全自动换源与docker一键安装换源

![](https://cdn.jsdelivr.net/gh/Master08s/img@main/img/202411081113060.png)

由于长久以来新服务器到手第一件事就是 **换源**
但是手动编辑也太麻烦了 于是我就写了这个脚本


---

脚本功能：
1.Ubuntu,Centos,Debian全自动换源
2.docker自动一键安装换源

![](https://cdn.jsdelivr.net/gh/Master08s/img@main/img/202411081114977.png)

换源后自动更新软件包 清楚缓存 修复依赖

-----
脚本运行命令

```

bash <(curl -sSL https://cdn.jsdelivr.net/gh/Master08s/ocss@latest/main.sh)
```
-----
修复与更新：

2024/11/7 13.00 1.0

----

2024/11/7 16.08 1.0 修复（修复缺少的可信镜像）

----

2024/11/7 17.00 2.0 更新  （为了帮助国内服务器正常安装docker添加安装路线选择，添加docker版本选择，一键完全卸载docker）

----

2024/11/8 10.52 3.0 更新 （新增了node.js一键换源与一键卸载功能）
一键换源支持了 下面的系统

![](https://cdn.jsdelivr.net/gh/Master08s/img@main/img/202411081111316.png)

---
