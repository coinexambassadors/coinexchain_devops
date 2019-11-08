# Validator + Sentry Nodes

**推荐：每个节点使用一台服务器**
**方案概述**

本方案使用两个`Sentry Node`节点，一个`Validator Node`节点，总计三台服务器。





## 使用Sentry nodes 方式部署Genesis节点

`sentry node` 是一个普通的全节点，负责与网络中的其它节点交换数据，同步区块、交易等数据。

### 部署 `sentry node`(普通全节点)






## 生成节点，获取节点的`Seed ID`

-   1.1 准备工具
	> sudo apt update <br>
	> sudo apt install -y ansible <br>

-   1.2 配置服务器的网络
    *   port(in TCP):
        *   `26656`: 需要打开，用于节点的P2P交流
        *   `26657`: 可以打开、也可以关闭，用于用户使用`cetcli`进行RPC 查询（如：账户信息、交易信息...）

-   1.3 在shell中设置链的参数
**示例**：`coinexdex-test1`测试链的参数

```
export CHAIN_ID=coinexdex-test1
export CHAIN_SEEDS=4d61ee17a695695c3139953c4e75fc0636121a3b@3.134.44.201:26656
export ARTIFACTS_BASE_URL=https://raw.githubusercontent.com/coinexchain/testnets/master/coinexdex-test2006
export CETD_URL=${ARTIFACTS_BASE_URL}/linux_x86_64/cetd
export CETCLI_URL=${ARTIFACTS_BASE_URL}/linux_x86_64/cetcli
export GENESIS_URL=${ARTIFACTS_BASE_URL}/genesis.json
export CETD_SERVICE_CONF_URL=${ARTIFACTS_BASE_URL}/cetd.service.example
export MD5_CHECKSUM_URL=${ARTIFACTS_BASE_URL}/md5.sum
```

-   1.4 设置环境变量参数，使用`/opt/cet`作为`sentry node`的部署目录

	> export RUN_DIR=~~`/opt/cet`~~ <br>
	> sudo mkdir -p ${RUN_DIR} <br>
	> sudo chown $USER ${RUN_DIR} <br>
	> export NODE_NAME='~~`ludete`~~' <br>

*   1.5 下载节点软件到服务器

> cd ${RUN_DIR}	<br>
> curl ${CETD_URL} > cetd <br>
> curl ${CETCLI_URL} > cetcli <br>
> curl ${GENESIS_URL} > genesis.json <br>
> curl ${CETD_SERVICE_CONF_URL} > cetd.service.example <br>
> chmod a+x ${RUN_DIR}/cetd ${RUN_DIR}/cetcli <br>

<details>
<summary>如何验证下载的软件?</summary>
> curl ${MD5_CHECKSUM_URL} > ${RUN_DIR}/md5.sum <br>
> md5sum ${RUN_DIR}/cetd ${RUN_DIR}/cetcli ${RUN_DIR}/genesis.json ${RUN_DIR}/cetd.service.example <br>
> 将生成的输出与文件中的数据进行比较
</details>

- 	1.6 初始化节点目录

> ${RUN_DIR}/cetd init ${VALIDATOR_MONIKER} --chain-id=${CHAIN_ID} --home=${RUN_DIR}/.cetd <br>
 

**注意：>>> 初始化时指定--home参数后, 后续所有cetd命令(包括cetd start启动节点)都需要加上--home参数.<<<**

-	1.7 应用下载的genesis.json 文件

>	cp ${RUN_DIR}/genesis.json ${RUN_DIR}/.cetd/config/genesis.json
>

- 	1.8 获取节点的 `seed id`

>  ${RUN_DIR}/cetd tendermint show-node-id --home=${RUN_DIR}/.cetd <br>
>


## Sentry Node 节点配置文件的设置

-  1.1 设置节点的配置文件(config.toml)

> ansible localhost -m ini_file -a "path=${RUN_DIR}/.cetd/config/config.toml section=p2p option=seeds  <br>
> value='\"${CHAIN_SEEDS}\"' backup=true" <br>
> #
> ansible localhost -m ini_file -a "path=${RUN_DIR}/.cetd/config/config.toml section=p2p option=persistent_peers <br>
> value='\"234d17ad72695c3139953c4e75fc0636121a3b@3.134.44.201:26656\"' backup=true" <br>
> #   	
> ansible localhost -m ini_file -a "path=${RUN_DIR}/.cetd/config/config.toml section=p2p option=private_peer_ids <br>
> value='\"3s2ee17a695695c3133423c4e75fc0636121a3b@3.134.44.201:26656\"' backup=true" <br>
> #
> ansible localhost -m ini_file -a "path=${RUN_DIR}/.cetd/config/config.toml section=p2p option=addr_book_strict <br> 
> value='false' backup=true" <br>
> #

- 	1.2 运行节点

参照下面运行节点的方案

## Validator Node 节点配置文件的设置

-  1.1 设置节点的配置文件(config.toml)
  
> ansible localhost -m ini_file -a "path=${RUN_DIR}/.cetd/config/config.toml section=p2p option=pex <br>
> value='false' backup=true" <br>
> # 
> ansible localhost -m ini_file -a "path=${RUN_DIR}/.cetd/config/config.toml section=p2p option=persistent_peers <br>
> value='\"1231e234a695345c3139953c4e75fc0636121a3b@3.134.44.201:26656\"' backup=true" <br>
> #   	
> ansible localhost -m ini_file -a "path=${RUN_DIR}/.cetd/config/config.toml section=p2p option=private_peer_ids <br>
> value='omitted' backup=true" <br>
> #
> ansible localhost -m ini_file -a "path=${RUN_DIR}/.cetd/config/config.toml section=p2p option=addr_book_strict <br> 
> value='false' backup=true" <br>
> #


- 	1.2 获取节点的共识私钥

## 运行节点


> ${RUN_DIR}/cetd start --home=${RUN_DIR}/.cetd <br>