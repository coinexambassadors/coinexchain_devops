## 简介

<details>
<summary>声明及内容格式:</summary>

### 声明
本文只是给出验证节点搭建的样例方案及相关的安全防护建议, 以便使节点运营者能够部署节点并加入CoinEx Chain.
网络中节点部署方案的多样性有利于整体网络稳定性及容错能力的提升, 我们鼓励节点运营者探索和实现自己独特的高可用及防双签方案, 并分享出来.

### 文本格式
- 本文中会使用以下格式来代表命令行操作的内容
    > \# 像本行一样#开头的行是注释 <br>
    > \# 像以下 ~~`<your_moniker_name>`~~ 这种样式的内容, 表示需要实际情况进行调整 <br>
    > export VALIDATOR_MONIKER=~~`<your_moniker_name>`~~

### 命令行参数说明
- 执行命令行时会用到一些参数, 需要在执行前在shell中通过`export`设定为环境变量
    - 一类是链的参数, 官方会发布, 比如`CHAIN_ID`, `SEEDS节点`的地址标识等
    - 另外一类是根据自己部署的环境需要调整的, 比如运行目录${RUN_DIR}

### 概念
- `SEEDS节点`: SEEDS节点会给网络中新加入的节点共享地址本, 以便使其发现网络中的其它节点.
- `cetd`:   节点后台进程, 参与P2P网络, 共识, 交易处理及数据存储.
- `cetcli`: 
    - 可生成新的私钥及地址, 默认存储在`~/.cetcli`
    - 做为与节点交互的工具, 可本地或远程查询节点状态和链上数据的信息
    - 可以通过cetcli的各个子命令, 构造未签名的各项业务交易
    - 可以通过cetcli的子命令, 将交易签名后, 发送到本地或远程节点, 进而被节点广播到P2P网络中
    - 详细请参考`cetcli help`命令

</details>

---

### 部署方案总述
下面会介绍几个递进的方案, 从最简单的部署方案(安全性可靠性较差)到较复杂的(安全性可靠性较好)部署方案.

- `方案1`: 单机Validator
    - 单机方案是最简单的部署, 但是安全性不够高
- `方案2`: 单机Validator + 哨兵节点
    - 加上哨兵节点隐藏和防护Validator后, 可以隐藏Validator机器的IP, 防止DDoS攻击
- `方案3`: Tendermint KMS + 单机Validator + 哨兵节点
    - 使用Tedermint KMS可以更好地保护节点的私钥, 同时也有进一步的防止节点双签的保护
- `方案4`: 安全性可靠性增强建议
    - 给出对网络进行更细致的防护及隔离的建议

<br>
<br>
<br>
<br>
<br>

---



## 方案1: 单机Validator

- 1.1 申请服务器
    <details>
    <summary>服务器配置建议:</summary>

    | 配置类别 | 正常配置               | 推荐配置               |                                     |
    |------|--------------------|--------------------|-------------------------------------|
    | CPU  | 4核                  | 4核                 | 类比AWS t3.large 或 t3.xlarge          |
    | 内存   | 8G                 | 16G                |                                     |
    | 硬盘   | 300G SSD           | 300G SSD           | 每月大概6G左右增长, 建议采用可扩容的EBS服务           |
    | 网络   | General purpose    | General purpose    | 类比AWS t3.large的网络, Up to 5 Gigabit  |
    | 系统   | `Ubuntu 18.04 64bit` | `Ubuntu 18.04 64bit` |
    ---
    </details>

- 1.1.1 工具准备
    > sudo apt update<br>
    > sudo apt install -y ansible

- 1.2 服务器网络配置
    - 端口列表(以下全部为TCP连接):
        - `26656`: 需要开放, 以便节点参与P2P通信. 
        - `26657`: 按需开放或只对可信网段开放, 主要供`cetcli`在远端进行RPC查询及操作.
        - `26659`: 如果使用下文中`方案3`时, 供与tmkms连接使用.
        - `1317`:  按需开放或只对可信网段开放, 供cetcli运行的rest-server使用, 提供基于REST接口的交互及swagger文档

- 1.3 在shell中执行官方公布的安装参数, 以便供后续脚本使用. `以下参数以coinexdex-test2002为示例`:
    > export CHAIN_ID=coinexdex-test2002<br>
    > export ARTIFACTS_BASE_URL=https://raw.githubusercontent.com/coinexchain/testnets/master/coinexdex-test2002<br>
    > export CETD_URL=${ARTIFACTS_BASE_URL}/linux_x86_64/cetd<br>
    > export CETCLI_URL=${ARTIFACTS_BASE_URL}/linux_x86_64/cetcli<br>
    > export GENESIS_URL=${ARTIFACTS_BASE_URL}/genesis.json<br>
    > export CETD_SERVICE_CONF_URL=${ARTIFACTS_BASE_URL}/cetd.service.example<br>
    > export MD5_CHECKSUM_URL=${ARTIFACTS_BASE_URL}/md5.sum<br>
    > export CHAIN_SEEDS=752ee6947aaafbfabc56938b4f65bfdf9a62e4bb@3.19.184.4:26656,7562b9dff832ddcd3f019d7a30262ba8bff7a383@18.189.200.85:26656<br>


- 1.4 确定安装参数, 以执行目录/home/ubuntu为例:
    > \#软件安装目录<br>
    > export RUN_DIR=~~`/home/ubuntu`~~<br>
    > \#节点名称, 比如My Awesome Node, 请保留下行中name前后的`'`号<br>
    > export VALIDATOR_MONIKER='~~`<your_moniker_name>`~~'<br>
    > \#节点的公网IP <br>
    > export VALIDATOR_PUBLIC_IP=~~`<validator_public_ip>`~~<br>


- 1.5 将软件包下载至服务器
    > \# 下载节点软件`cetd`, 节点客户端`cetcli`, 及网络初始配置`genesis.json`<br>
    > cd ${RUN_DIR}<br>
    > curl ${CETD_URL} > cetd<br>
    > curl ${CETCLI_URL} > cetcli<br>
    > curl ${GENESIS_URL} > genesis.json<br>
    > curl ${CETD_SERVICE_CONF_URL} > cetd.service.example<br>
    > chmod a+x ${RUN_DIR}/cetd ${RUN_DIR}/cetcli
    <details>
    <summary>软件包校验:</summary>

    发布时官方会在软件包同级目录提供相应软件的md5, 请自行进行下载软件的校验, 以保证下载了正确的版本.<br>
    > curl ${MD5_CHECKSUM_URL} > ${RUN_DIR}/md5.sum<br>
    > md5sum ${RUN_DIR}/cetd ${RUN_DIR}/cetcli ${RUN_DIR}/genesis.json ${RUN_DIR}/cetd.service.example<br>
     \#然后比较md5.sum文件内容与实际输出, 确认一致
    ---
    </details>

- 1.6 初始化节点数据
    > ${RUN_DIR}/cetd init ${VALIDATOR_MONIKER} --chain-id=${CHAIN_ID}

    **`NOTES: >>>YOUR NODE's CONSENSUS PUBKEY are generated in ~/.cetd, PLEASE DO BACKUP.<<<`**
    <details>
    <summary>建议进行节点私钥备份:</summary>
    本步骤会将节点启动时的配置及数据目录(默认为 ~/.cetd )进行初始化, >>>请备份并保管好以下文件<<< <br>

    ```shell
    /home/ubuntu/.cetd
    ├── config
    │   ├── app.toml                   <- 业务层配置
    │   ├── config.toml                <- 共识及P2P层配置
    │   ├── genesis.json               <- 网络初始状态, >>>需用官方公布的`genesis.json`替换<<<
    │   ├── node_key.json              <- p2p层加密认证使用. used for p2p authenticated encryption
    │   └── priv_validator_key.json    <- 节点私钥, >>>需保护好, 防止私钥被盗后发生共识层的双签而被惩罚<<<
    └── data
        └── priv_validator_state.json  <- 节点共识最新状态
    ```
    ---
    </details>  

- 1.7 应用网络初始配置genesis.json
    > cp ${RUN_DIR}/genesis.json ~/.cetd/config/genesis.json

- 1.8 设置节点对外IP地址.
    > ansible localhost -m ini_file -a "path=${RUN_DIR}/.cetd/config/config.toml section=p2p option=external_address value='\\"tcp://${VALIDATOR_PUBLIC_IP}:26656\\"' backup=true"

- 1.8.1 设置节点对外RPC地址<br>
    节点RPC端口默认监听127.0.0.1. 如果需要远程通过`cetcli`与节点交互, 需要修改服务监听地址为`0.0.0.0`
    > ansible localhost -m ini_file -a "path=${RUN_DIR}/.cetd/config/config.toml section=rpc option=laddr value='\\"tcp://0.0.0.0:26657\\"' backup=true"

- 1.9 配置网络中的seeds节点信息. 取值使用$CHAIN_SEEDS的值
    > ansible localhost -m ini_file -a "path=${RUN_DIR}/.cetd/config/config.toml section=p2p option=seeds value='\\"${CHAIN_SEEDS}\\"' backup=true"
    
- 1.10 启动全节点
    <br>可通过以下命令来启动节点, 但推荐使用Systemd/Supervisor等来启动.
    > nohup ${RUN_DIR}/cetd start &

    <details>
    <summary>1.10-操作样例, 以`systemd`管理`cetd`举例:</summary>

    **<br>`以下是样例, 具体systemd配置细节及日志管理, 请自行设计方案`**    

    > sudo mv ${RUN_DIR}/cetd.service.example /etc/systemd/system/cetd.service<br>
    > sudo ln -s /etc/systemd/system/cetd.service /etc/systemd/system/multi-user.target.wants/cetd.service<br>
    > sudo systemctl daemon-reload<br>
    > sudo systemctl status cetd<br>
    > sudo systemctl start cetd<br>
    > sudo systemctl status cetd
    ---
    </details>  
    <br>

    <details>
    <summary>1.10.1 将cetd配置为系统服务:</summary>

    - 建议将cetd设置为系统服务, 通过Systemd或Supervisor等软件来管理cetd进程状态及其日志.
    - 这样即使cetd特殊场景下进程退出, 也可以被systemd重新拉起进程, 避免节点长时间不在线, 因可用性差而被惩罚.
    <br><br>
    ---
    </details>

    <details>
    <summary>1.10.2 提高cetd进程的可用文件句柄数量为655360:</summary>

    - 设置过程可参考[链接](https://medium.com/@muhammadtriwibowo/set-permanently-ulimit-n-open-files-in-ubuntu-4d61064429a)
    - 如果使用systemd管理cetd, 可以在`[Unit]` Section中增加配置: `LimitNOFILE=655360`
    - 检查设置是否成功:
        > prlimit -p $(pidof cetd) | grep NOFILE<br>

        ```
        ubuntu@ip-172-31-5-201:~$ prlimit -p `pidof cetd` | grep NOFILE
        NOFILE     max number of open files              655360    655360 files
        ```
    ---
    </details> 

    <details>
    <summary>1.10.3 (可选)打开cetd进程CoreDump配置:</summary>

    - 进程非正常退出时, 如果能够生成CoreDump文件, 将得到当时更多的上下文.
    - 如果使用systemd管理cetd, 可以在`[Unit]` Section中增加配置: `LimitCORE=infinity`
    - 检查设置是否成功:
        > prlimit -p $(pidof cetd) | grep CORE<br>

        ```
        ubuntu@ip-172-31-5-201:~$ prlimit -p `pidof cetd` | grep CORE
        CORE       max core file size                 unlimited unlimited bytes
        ```

    ---
    <br><br>
    
    </details>  


- 1.11 检查节点状态
    > ${RUN_DIR}/cetcli status<br>

    检查输出:
    - `"id":"b5fedfeb14b7b84908ea0fc85b8799a1e78000fd"`  是节点在p2p网络中的ID
    - `"rpc_address":"tcp://0.0.0.0:26657"`     RPC端口可远程访问
    - `"rpc_address":"tcp://127.0.0.1:26657"`   RPC端口只可本地访问
    - `"latest_block_height":"83274"`  本节点当前高度
    - `"catching_up":true|false`  表示当前是否正在从网络同步区块, false表示已经是最新块状态

- 1.12 获取节点共识consensus pubkey, 供后续创建验证节点使用
    > echo "export VALIDATOR_CONSENSUS_PUBKEY=$(${RUN_DIR}/cetd tendermint show-validator)"<br> 

    
    样例输出: (测试网前缀cettestvalconspub, 主网前缀coinexvalconspub)

    ```
    export VALIDATOR_CONSENSUS_PUBKEY=cettestvalconspub1zcjduepqn926zz0lqt9dt83xfn9vflnxhrem644ep4k4qkgz2fjpef3402mqeuf2yz
    ```

<br>
<br>
<br>
<br>
<br>


---
- 到目前为止, 就可以通过广播一个CreateValidator交易到网络, 来将节点设置为验证人.<br>
    - 需要以下条件:<br>
        - 准备一个CoinEx Chain的帐户, 以便能够做为验证节点运营者Validator Operator进行相关交易签名
        - 帐户需要有运营节点足够金额的CET用来做初始质押, 主网目前暂定500w CET, 以官方公布为准.

- 后续创建帐户及将节点设置为验证节点, 不需要在云服务器上操作. 可以保证用户帐户私钥不会出现在服务器上.
---

<br>
<br>
<br>
<br>
<br>

- 1.12 [个人电脑]以下切换到个人电脑上操作 (个人电脑假设同样为`Ubuntu 18.04`).
    - 个人电脑上重复执行 `1.3`及`1.4`步骤内容, 以便使个人电脑shell中也能找到相关的环境参数
    - 检查环境变量中以下变量有值:
    > [ "${VALIDATOR_PUBLIC_IP}" != "" ] && echo "OK" || echo "ERROR"<br>
    > [ "${CETCLI_URL}" != "" ] && echo "OK" || echo "ERROR"<br>
    > [ "${VALIDATOR_MONIKER}" != "" ] && echo "OK" || echo "ERROR"<br>
    > [ "${CHAIN_ID}" != "" ] && echo "OK" || echo "ERROR"<br>


- 1.13 [个人电脑]在个人电脑上下载cetcli, 并设置cetcli连接远端搭建的服务器节点.
    > curl ${CETCLI_URL} > cetcli<br>
    > chmod a+x ./cetcli<br>
    > ./cetcli config node ${VALIDATOR_PUBLIC_IP}:26657<br>
    > \# 执行cetcli status查看确认已经连接到了远程节点<br>
    > ./cetcli status | grep ${VALIDATOR_PUBLIC_IP}  && echo "OK" || echo "ERROR"<br>

- 1.14 [个人电脑]创建帐户<br>
    **`NOTES: >>>your mnemonic passphrase will print out by this command, store it safely<<<`**<br>
    **`NOTES: >>>your private keystore will be in folder: ~/.cetcli, PLEASE DO BACKUP<<<`**
    > \#example export KEY_NAME=my_key<br>
    > export KEY_NAME=~~`<replace_with_your_local_key_name>`~~ <br>
    > ./cetcli keys add ${KEY_NAME}<br>

    <details>
    <summary>example output:</summary>

    ```
    j@j ~ $ export KEY_NAME=bob
    j@j ~ $ ./cetcli keys add ${KEY_NAME}
    Enter a passphrase to encrypt your key to disk:
    Repeat the passphrase:

    - name: bob
    type: local
    address: cettest1wrl8lzre3u05msrlagxkx7e4q0szp4usjpcy0z
    pubkey: cettestpub1addwnpepqwrxg3amuqzmnrc6m3rlx26z5y63zlwcfu8zdqa4nmsr2zr2ez35kdxwc9e
    mnemonic: ""
    threshold: 0
    pubkeys: []


    **Important** write this mnemonic phrase in a safe place.
    It is the only way to recover your account if you ever forget your password.

    pelican someone great yard electric quick embark hazard surprise yard picture draft student tilt volume solve charge price grit jealous problem door rent evolve
    j@j ~ $
    ```
    ---
    <br><br>
    </details>  

- 1.15 [个人电脑] 查到帐户地址后, 可从CoinEx交易所提现操作到链上地址.
    > export VALIDATOR_OPERATOR_ADDR=$(./cetcli keys show ${KEY_NAME} -a)<br>
    > [ "${VALIDATOR_OPERATOR_ADDR}" != "" ] && echo "OK" || echo "ERROR"<br>
    > echo ${VALIDATOR_OPERATOR_ADDR}

    如果是测试网络, 可以从水龙头获取测试币. 水龙头地址请查找[链接](https://github.com/coinexchain/testnets)<br>
    比如: 测试网`coinexdex-test2002`[水龙头地址](http://18.189.200.85/)

- 1.16 [可选] 查询地址余额:
    > ./cetcli q account $(./cetcli keys show ${KEY_NAME} -a) --chain-id=${CHAIN_ID}

    如果显示`"account ... does not exist"`是帐户地址还没有在链上出现过, 或者节点还没有同步到执行转帐交易的高度.

    ```
    j@j ~ $ ./cetcli q account $(./cetcli keys show ${KEY_NAME} -a) --chain-id=${CHAIN_ID}
    account: |
    address: cettest1wrl8lzre3u05msrlagxkx7e4q0szp4usjpcy0z
    coins:
    - denom: cet
        amount: "1499900000000"
    ```
    
    `注意: 链上所有token精度为8位, 以上1499900000000cet 相当于 14999CET`<br>
    `另外少了一个CET, 是因为帐户初次激活费会扣除1CET做为激活功能费`<br>
    `NOTES: All tokens' precision are fixed at 8 decimal digits,`<br>
    `so in previous example 1499900000000cet on chain means 14999CET`<br>
    `One CET will be charged as account activation feature fee`<br>

- 1.17.1 发送成为验证者节点的交易
    - 个人电脑上执行`1.12`中的输出, 以便个人电脑shell能找到`${VALIDATOR_CONSENSUS_PUBKEY}`
    - 检查一下节点共识公钥是否已在shell中可用:
        > [ "${VALIDATOR_CONSENSUS_PUBKEY}" != "" ] && echo "OK" || echo "ERROR"<br>

- 1.17.2 准备节点的identity, 以便自定义的验证人节点图标<br>
    - 从https://keybase.io网站注册后, 上传自定义图标, 并获得相应的identity
    - 比如[ViaWallet](https://keybase.io/viawallet)在测试网中使用的identity是`9A30CBDA5872CED8`
    - 导出:
    > export VALIDATOR_IDENTITY=~~`<REPLACE_WITH_YOUR_IDENTITY>`~~<br>
    > [ "${VALIDATOR_IDENTITY}" != "" ] && echo "OK" || echo "ERROR"<br>

- 1.17.3 发送交易
    > \# Send CreateValidator tx to become a validator<br>
    > ./cetcli tx staking create-validator \\\
    --amount=500000000000000cet \\\
    --pubkey=${VALIDATOR_CONSENSUS_PUBKEY} \\\
    --moniker=${VALIDATOR_MONIKER} \\\
    --identity=${VALIDATOR_IDENTITY} \\\
    --chain-id=${CHAIN_ID} \\\
    --commission-rate=0.1 \\\
    --commission-max-rate=0.2 \\\
    --commission-max-change-rate=0.01 \\\
    --min-self-delegation=500000000000000 \\\
    --from $(./cetcli keys show ${KEY_NAME} -a) \\\
    --gas 300000 \\\
    --fees 6000000cet

    <details>
    <summary>cetcli tx staking create-validator --help:</summary>

    ```
    create new validator initialized with a self-delegation to it
    Flags:
        --amount string                       Amount of coins to bond
        --commission-max-change-rate string   The maximum commission change rate percentage (per day)
        --commission-max-rate string          The maximum commission rate percentage
        --commission-rate string              The initial commission rate percentage
        --details string                      The validator's (optional) details
        --from string                         Name or address of private key with which to sign
        --gas string                          gas limit; set to "auto" to calculate required gas automatically
        --identity string                     The optional identity signature (ex. Keybase)
        --memo string                         Memo to send along with transaction
        --min-self-delegation string          The minimum self delegation required on the validator
        --moniker string                      The validator's name
        --pubkey string                       The Bech32 encoded PubKey of the validator
        --website string                      The validator's (optional) website
        --chain-id string                     Chain ID of tendermint node
    ```

    另外浏览器的描述及identity信息, 可通过edit-validator命令来修改
    > ./cetcli tx staking edit-validator --help
    ---
    <br>
    </details> 

    - notes, gas can be estimated by using --dry-run (without --gas and --fees parameter)
        - `All tokens' precision are fixed at 8 decimal digits.`
        - `so 200000000cet on chain means 2CET`
        - `current network min gas price is 20cet/gas on chain. `
        - `means 0.0000002CET/gas`

    - **`NOTES: 节点佣金是Delegator选择Validator的重要参考项之一, 需要谨慎选择和填写:`**
        - --amount string
            - 表示创建节点时, 初始自质押的CET数量
            - 须大于等于共识的最小质押量参数, 目前为500万CET
        - --commission-rate=0.1<br>
            - 表示节点当前的佣金, 0.1表示10%佣金.
        - --commission-max-rate=0.2<br>
            - 表示节点将来可能设定的最大佣金, 创建验证节点人后 **`佣金最大值不可变更`**
        - --commission-max-change-rate=0.01<br>
            - 表示承诺的24小时内佣金最大调整量, 0.01表示本节点佣金每次调整最大量为1%<br>
            - 另外24小时内只可调整一次
        - --min-self-delegation=500000000000000<br>
            - 表示节点承诺的最少自质押量.<br>
            - 节点undelegate取回自己的部分CET后, 如果节点自质押量小于min-self-delegation将变成非激活节点.
            - 须大于等于共识的最小质押量参数, 目前为500万CET

<details>
<summary>查询验证人节点状态:</summary>

- Check your validator status in [CoinEx DEX Chain Explorer](https://explorer.coinex.org/validators)
    - 测试网浏览器请查找[链接](https://github.com/coinexchain/testnets)

- Get your validator operator address
    > cetcli keys show ${KEY_NAME} --bech val
    ```
    NAME:	TYPE:	ADDRESS:					
    fullnode_user1	local	coinexvaloper1kg3e5p2rc2ejppwts6qwzrcgndvgeyztudujdz	

    #coinexvaloper1kg3e5p2rc2ejppwts6qwzrcgndvgeyztudujdz is your validator operator address
    ```

- Query all validators
    > cetcli q staking validators --chain-id=${CHAIN_ID}
    ```
    Validator
    Operator Address:           coinexvaloper1kg3e5p2rc2ejppwts6qwzrcgndvgeyztudujdz
    Validator Consensus Pubkey: coinexvalconspub1zcjduepqagvj8plupgura2vt08xlm3tpur5u0vw89cw8ut9j8a55xq2jetgswccuwt
    Jailed:                     false
    Status:                     Bonded
    Tokens:                     100000000000000
    Delegator Shares:           100000000000000.000000000000000000
    Description:                {fullnode1   }
    Unbonding Height:           0
    Unbonding Completion Time:  1970-01-01 00:00:00 +0000 UTC
    Minimum Self Delegation:    100000000000000
    Commission:                 rate: 0.050000000000000000, maxRate: 0.200000000000000000, maxChangeRate: 0.010000000000000000, updateTime: 2019-06-23 

    ...
    ```

- Do I in vaidator set?
    > ./cetcli q tendermint-validator-set --chain-id=${CHAIN_ID} | grep $(./cetd tendermint show-validator) && echo "in validator set" || echo "not in validator set"

    输出"in validator set"时, 表示相关你的验证人节点已经建立完成.

- How to unjail my validator?
	```
	cetcli tx slashing unjail --from ${KEY_NAME} --chain-id=${CHAIN_ID} --gas=100000 --fees=2000000cet
	```

    ---
    <br>
    </details> 


<br>
<br>
<br>
<br>
<br>

---
至此已经完成单机Validator的部署
- 后续的增强部署, 建议在[测试网](https://github.com/coinexchain/testnets)演练正常后再进行主网的部署

---
<br>
<br>
<br>
<br>
<br>


---


## 方案2: Validator + 哨兵节点

- 哨兵节点方案请参考[链接](https://forum.cosmos.network/t/sentry-node-architecture-overview/454)

<br>
<br>
<br>
<br>
<br>


---


## 方案3: Tendermint KMS + Validator + 哨兵节点
- [什么是Tendermint KMS?](https://github.com/tendermint/kms)
- 工具编译请参考[链接](https://github.com/tendermint/kms#installation)
- 配置请参考[链接](https://github.com/tendermint/kms#usage)

<br>
<br>
<br>
<br>
<br>

---


## 方案4: 安全性可靠性增强建议

- 稍候补充:

<br>
<br>
<br>
<br>
<br>

---

## Community and Docs
- [Join developer channel](https://join.slack.com/t/coinexchain/shared_invite/enQtNzA0NjU5ODc3MjM0LTk3NWUzMDA2YmU0NTc5MDg2NDI3NmRjM2VkNzYzNjIyZWM0NzZhMWIwMWQxNGJjNmI3NjVkZWIxZWUwNjJmYTI)
- [Docs](https://github.com/coinexchain/dex-manual)
- [FAQ](https://github.com/coinexchain/dex-manual/blob/01222ef03f4c94231f851ccd3d82e20cb899bb61/docs/02_faq.md)
  - Please read Doc and FAQ before setup your validators

## References
1. https://forum.cosmos.network/t/sentry-node-architecture-overview/454
