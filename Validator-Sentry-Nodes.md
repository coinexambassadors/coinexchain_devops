# Validator + Sentry Nodes

**推荐：每个节点使用一台服务器**

**方案概述**

本方案使用两个`Sentry Node`节点，一个`Validator Node`节点，总计三台服务器。


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

> ${RUN_DIR}/cetd init ${NODE_NAME} --chain-id=${CHAIN_ID} --home=${RUN_DIR}/.cetd <br>
 

**注意：>>> 初始化时指定--home参数后, 后续所有cetd命令(包括cetd start启动节点)都需要加上--home参数.<<<**

-	1.7 应用下载的genesis.json 文件

>	cp ${RUN_DIR}/genesis.json ${RUN_DIR}/.cetd/config/genesis.json
>

- 	1.8 获取节点的 `seed id`

>  ${RUN_DIR}/cetd tendermint show-node-id --home=${RUN_DIR}/.cetd <br>
>

将获取的seed id 记录下来，在接下来节点的配置文件中需要使用.

<br>

## Sentry Node 节点配置文件的设置

-	1.1 设置Validator的seed id

>	export RUN_DIR=~~`/opt/cet`~~ <br>
>	export VALIDATOR_ID=234d17ad72695c3139953c4e75fc0636121a3b@3.134.44.201:26656 <br>
>	export CHAIN_SEEDS=4d61ee17a695695c3139953c4e75fc0636121a3b@3.134.44.201:26656 <br>

-  1.2 设置节点的配置文件(config.toml)

> ansible localhost -m ini_file -a "path=${RUN_DIR}/.cetd/config/config.toml section=p2p option=seeds value='\\"${CHAIN_SEEDS}\\"' backup=true" <br>
> #
> ansible localhost -m ini_file -a "path=${RUN_DIR}/.cetd/config/config.toml section=p2p option=persistent_peers value='\\"${VALIDATOR_ID}\\"' backup=true" <br>
> #
> ansible localhost -m ini_file -a "path=${RUN_DIR}/.cetd/config/config.toml section=p2p option=private_peer_ids value='\\"${VALIDATOR_ID}\\"' backup=true" <br>
> #
> ansible localhost -m ini_file -a "path=${RUN_DIR}/.cetd/config/config.toml section=p2p option=addr_book_strict value='false' backup=true" <br>
> #

*	seeds: cetd网络的种子节点标识，用于帮助新节点接入整个cetd网络，与网络中的其它节点进行交流。
*	persistent_peers: 配置`validator`节点的标识，会持久链接`validator`节点，断开时，会进行重链；如果未在此处配置这个值，可能`sentry node`在达到链接最大值时，将与`validator`节点的链接随机断开。   	
*	private_peer_ids: 配置`validator`节点的标识，当`sentry node`与网络中的其它节点进行IP地址交换时，不会将该IP地址暴露出去.
*	addr_book_strict: 配置为true，允许`sentry node`链接不可路由的IP地址节点，因为`validator`可以处于保护的目的，处于内网中，不提供对外的IP地址。


- 	1.2 运行节点

[参照下面的节点运行方案](https://github.com/coinexchain/devops/blob/master/Validator-Sentry-Nodes.md#%E8%BF%90%E8%A1%8C%E8%8A%82%E7%82%B9)

<br>

## Validator Node 节点配置文件的设置

-	1.1 设置 sentry node 的seed id

>	export RUN_DIR=~~`/opt/cet`~~ <br>
> 	export SENTRY_NODE_IDS=234d17ad72695c3139953c4e75fc0636121a3b@3.134.44.201:26656, 1231e234a695345c3139953c4e75fc0636121a3b@30.124.14.231:26656

-  1.2 设置节点的配置文件(config.toml)
  
> ansible localhost -m ini_file -a "path=${RUN_DIR}/.cetd/config/config.toml section=p2p option=pex value='false' backup=true" <br>
> #
> ansible localhost -m ini_file -a "path=${RUN_DIR}/.cetd/config/config.toml section=p2p option=persistent_peers value='\\"${SENTRY_NODE_IDS}\\"' backup=true" <br>
> #
> ansible localhost -m ini_file -a "path=${RUN_DIR}/.cetd/config/config.toml section=p2p option=addr_book_strict value='false' backup=true" <br>
> #

*	pex: 设置为false,禁止validator节点与sentry node节点交换地址簿，保护validator节点的IP地址不会被泄漏出去.<br>
*	persistent_peers: 用`逗号`分隔的`sentry node`节点的标识，validator链接这些`sentry node`节点与整个网络沟通.因为pex标识设置为false,如果验证者节点未配置这个值，会导致validator节点无法加入网络. <br>
*	addr_book_strict: 设置为true，允许validator链接不可路由的内网IP的`sentry node`节点;因为有可能`validator`与`sentry node`位于同一个私有网络，它们之间通过私有网络进行交流. <br>

- 	1.3  获取节点的共识consensus pubkey, 供后续创建验证节点使用

>	echo "export VALIDATOR_CONSENSUS_PUBKEY=$(${RUN_DIR}/cetd tendermint show-validator --home=${RUN_DIR}/.cetd)" <br>

样例输出: (测试网前缀`cettestvalconspub`, 主网前缀`coinexvalconspub`)

`cettestvalconspub1zcjduepqn926zz0lqt9dt83xfn9vflnxhrem644ep4k4qkgz2fjpef3402mqeuf2yz
`

-	1.4  运行节点

[参照下面的节点运行方案](https://github.com/coinexchain/devops/blob/master/Validator-Sentry-Nodes.md#%E8%BF%90%E8%A1%8C%E8%8A%82%E7%82%B9)

-	1.5 将该节点设置为 Validator 节点

[参照下面的将节点设置为Validator的方案](https://github.com/coinexchain/devops/blob/master/Validator-Sentry-Nodes.md#%E5%B0%86%E8%8A%82%E7%82%B9%E8%AE%BE%E7%BD%AE%E4%B8%BAvalidator)

<br>

## [运行节点]:

可通过以下命令来启动节点, 但推荐使用Systemd/Supervisor等来启动.

> ${RUN_DIR}/cetd start --home=${RUN_DIR}/.cetd <br>
> 

<details>
<summary> 以`systemd`管理`cetd`举例:</summary>
	
**1.1 以下是样例,具体systemd配置细节及日志管理, 请自行设计方案**

>	ansible localhost -m ini_file -a "path=${RUN_DIR}/cetd.service.example section=Service option=ExecStart value='${RUN_DIR}/cetd start --home=${RUN_DIR}/.cetd' backup=true"	<br>
>	sudo mv ${RUN_DIR}/cetd.service.example /etc/systemd/system/cetd.service	<br>
>	sudo ln -s /etc/systemd/system/cetd.service /etc/systemd/system/multi-user.target.wants/cetd.service	<br>
>	sudo systemctl daemon-reload	<br>
>	sudo systemctl status cetd		<br>
>	sudo systemctl start cetd		<br>
>	sudo systemctl status cetd		<br>


**1.2 将cetd配置为系统服务**

*	建议将cetd设置为系统服务, 通过Systemd或Supervisor等软件来管理cetd进程状态及其日志.
*	这样即使cetd特殊场景下进程退出, 也可以被systemd重新拉起进程, 避免节点长时间不在线, 因可用性差而被惩罚.

**1.3 提高cetd进程的可用文件句柄数量为655360**

*	设置过程可参考[链接](https://medium.com/@muhammadtriwibowo/set-permanently-ulimit-n-open-files-in-ubuntu-4d61064429a)
* 	如果使用systemd管理cetd, 可以在[Unit] Section中增加配置: `LimitNOFILE=655360`
*	检查设置是否成功:

	>	prlimit -p $(pidof cetd) | grep NOFILE
	
	```
	ubuntu@ip-172-31-5-201:~$ prlimit -p `pidof cetd` | grep NOFILE
	NOFILE     max number of open files              655360    655360 files
	```

**1.4 (可选)打开cetd进程CoreDump配置:**

*	进程非正常退出时, 如果能够生成CoreDump文件, 将得到当时更多的上下文
* 	如果使用systemd管理cetd, 可以在[Unit] Section中增加配置: LimitCORE=infinity
*  检查设置是否成功:

	>	prlimit -p $(pidof cetd) | grep CORE
	
	```
	ubuntu@ip-172-31-5-201:~$ prlimit -p `pidof cetd` | grep CORE
	CORE       max core file size                 unlimited unlimited bytes
	```

**1.5 检查节点状态**

>	${RUN_DIR}/cetcli status	<br>

检查输出：

*	`"id":"b5fedfeb14b7b84908ea0fc85b8799a1e78000fd"` 是节点在p2p网络中的ID
* 	`"rpc_address":"tcp://0.0.0.0:26657"`RPC端口可远程访问
*	`"rpc_address":"tcp://127.0.0.1:26657"` RPC端口只可本地访问
*	`"latest_block_height":"83274"` 本节点当前高度
* 	`"catching_up":true|false` 表示当前是否正在从网络同步区块, false表示已经是最新块状态

</details>

<br>

## 将节点设置为Validator

获取节点的共识`consensus pubkey`； 即1.3节命令行输出的应答

>	export VALIDATOR_CONSENSUS_PUBKEY=cettestvalconspub1zcjduepqn926zz0lqt9dt83xfn9vflnxhrem644ep4k4qkgz2fjpef3402mqeuf2yz <br>

------------

*	到目前为止, 就可以通过广播一个CreateValidator交易到网络, 来将节点设置为验证人.
	* 	需要以下条件:
		*  准备一个CoinEx Chain的帐户, 以便能够做为验证节点运营者Validator Operator进行相关交易签名
		*  帐户需要有运营节点足够金额的CET用来做初始质押, 主网目前暂定500w CET, 以官方公布为准.
*	后续创建帐户及将节点设置为验证节点, 不需要在云服务器上操作. 可以保证用户帐户私钥不会出现在服务器上

-------------

**以下操作切换到个人电脑上 (个人电脑假设同样为Ubuntu 18.04)**

-	1.1 设置环境变量

>	export CETCLI_URL=${ARTIFACTS_BASE_URL}/linux_x86_64/cetcli <br>
>	export SENTRY_NODE_PUBLIC_IP=~~<validator_public_ip>~~ <br>
> 	export VALIDATOR_MONIKER=~~<moniker_name>~~ <br>
>  export CHAIN_ID=coinexdex-test1	<br>
`export ARTIFACTS_BASE_URL=https://raw.githubusercontent.com/coinexchain/testnets/master/coinexdex-test2006`

`RUN_DIR` 为用户的自定义工作目录，以下示例以`/opt/node`为例

>	export RUN_DIR=~~/opt/node~~		<br>
>	sudo mkdir -p ${RUN_DIR}	<br>
>	sudo chown $USER ${RUN_DIR}	<br>
>	cd ${RUN_DIR}	<br>

*	检查环境变量

>	[ "${SENTRY_NODE_PUBLIC_IP}" != "" ] && echo "OK" || echo "ERROR" <br>
>	[ "${CETCLI_URL}" != "" ] && echo "OK" || echo "ERROR" <br>
>	[ "${VALIDATOR_MONIKER}" != "" ] && echo "OK" || echo "ERROR" <br>
>	[ "${CHAIN_ID}" != "" ] && echo "OK" || echo "ERROR" <br>
>

-	1.2 下载cetcli，并设置cetcli链接远端搭建的节点

>	curl ${CETCLI_URL} > cetcli <br>
>	chmod a+x ./cetcli <br>
>	${RUN_DIR}/cetcli config node ${SENTRY_NODE_PUBLIC_IP}:26657 <br>
>	#查看是否可以链接到远端节点 <br>
>  ${RUN_DIR}/cetcli status <br>	
> 

-	1.3 创建帐户

**注意 1: >>>帐户的助记词会在这个命令中输出, 请一定记得保管!!!!!!<<<**
**注意 2: >>>你的keystore文件会存储在: ~/.cetcli 中, 也请一定备份这个目录<<<**
**注意 3: >>>也需要记住相应帐户的keystore加密密码, 后续才能使用相应的帐户<<<**

>	#example export KEY_NAME=my_key <br>
>	export KEY_NAME=<replace_with_your_local_key_name> <br>
>	${RUN_DIR}/cetcli keys add ${KEY_NAME}	<br>
>

<details>
<summary>示例输出</summary>

```
j@j ~ $ export KEY_NAME=bob
j@j ~ $ ${RUN_DIR}/cetcli keys add ${KEY_NAME}
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

</details>

-	1.4 从CoinEx交易所提现操作到该创建地址

	>	export VALIDATOR_OPERATOR_ADDR=$(${RUN_DIR}/cetcli keys show ${KEY_NAME} -a) <br>
	>	[ "${VALIDATOR_OPERATOR_ADDR}" != "" ] && echo "OK" || echo "ERROR" <br>
	>	echo ${VALIDATOR_OPERATOR_ADDR} <br>

如果是测试网络, 可以从水龙头获取测试币. 水龙头地址请查找[链接](https://github.com/coinexchain/testnets)
比如: 测试网`coinexdex-test2006` [水龙头地址](http://18.228.254.51/)

-	1.5 查询地址余额

	>	${RUN_DIR}/cetcli q account $(${RUN_DIR}/cetcli keys show ${KEY_NAME} -a) --chain-id=${CHAIN_ID}

	如果显示`"account ... does not exist"`是帐户地址还没有在链上出现过, 或者节点还没有同步到执行转帐交易的高度.
	
	```
	j@j ~ $ ${RUN_DIR}/cetcli q account $(./cetcli keys show ${KEY_NAME} -a) --chain-id=${CHAIN_ID}
	account: |
	address: cettest1wrl8lzre3u05msrlagxkx7e4q0szp4usjpcy0z
	coins:
	- denom: cet
	    amount: "1499900000000"
	```
	
	`注意: 链上所有token精度为8位, 以上1499900000000cet 相当于 14999CET`
	`另外少了一个CET, 是因为帐户初次激活费会扣除1CET做为激活功能费`
	`NOTES: All tokens' precision are fixed at 8 decimal digits,`
	`so in previous example 1499900000000cet on chain means 14999CET`
	`One CET will be charged as account activation feature fee`

-	1.6 发送成为验证者节点的交易

	*	检查是否已在本机配置将要设置的节点共识`consensus pubkey`

	>	[ "${VALIDATOR_CONSENSUS_PUBKEY}" != "" ] && echo "OK" || echo "ERROR"

-	1.7 准备节点的identity, 以便自定义的验证人节点图标

	*	从[https://keybase.io网站注册](https://keybase.io/)后, 上传自定义图标, 并获得相应的identity
	* 	比如[ViaWallet](https://keybase.io/viawallet)在测试网中使用的identity是9A30CBDA5872CED8

	<details>
	<summary>示例</summary>
	[图片](https://github.com/coinexchain/devops/raw/master/images/keybase_identity.png)
	</details>

	*	导出identity
	>	export VALIDATOR_IDENTITY=~~<REPLACE_WITH_YOUR_IDENTITY>~~ <br>
	>	[ "${VALIDATOR_IDENTITY}" != "" ] && echo "OK" || echo "ERROR" <br>

-	1.8 发送交易，使节点成为验证者

>	#Send CreateValidator tx to become a validator<br>
>	${RUN_DIR}/cetcli tx staking create-validator \ <br>
>	--amount=500000000000000cet \ <br>
>	--pubkey=${VALIDATOR_CONSENSUS_PUBKEY} \ <br>
>	--moniker=${VALIDATOR_MONIKER} \ <br>
>	--identity=${VALIDATOR_IDENTITY} \ <br>
>	--chain-id=${CHAIN_ID} \ <br>
>	--commission-rate=0.1 \ <br>
>	--commission-max-rate=0.2 \ <br>
>	--commission-max-change-rate=0.01 \ <br>
>	--min-self-delegation=500000000000000 \ <br>
>	--from $(./cetcli keys show ${KEY_NAME} -a) \ <br>
>	--gas 300000 \	<br>
>	--fees 6000000cet <br>
>

<details>
<summary>${RUN_DIR}/cetcli tx staking create-validator --help</summary>

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

*	NOTES: 节点佣金是Delegator选择Validator的重要参考项之一, 需要谨慎选择和填写:

	*	--amount string 表示创建节点时, 初始自质押的CET数量
		*	须大于等于共识的最小质押量参数, 目前为500万CET
	*	--commission-rate=0.1
		* 表示节点当前的佣金, 0.1表示10%佣金.
	*	--commission-max-rate=0.2
		*	表示节点将来可能设定的最大佣金, 创建验证节点人后 佣金最大值不可变更
	*	--commission-max-change-rate=0.01
		*	表示承诺的24小时内佣金最大调整量, 0.01表示本节点佣金每次调整最大量为1%
		*	另外24小时内只可调整一次
	*	--min-self-delegation=500000000000000
		*	表示节点承诺的最少自质押量.
		*	节点undelegate取回自己的部分CET后, 如果节点自质押量小于min-self-delegation将变成非激活节点.
		*	须大于等于共识的最小质押量参数, 目前为500万CET

另外节点的描述及identity信息, 可通过edit-validator命令来修改
>	${RUN_DIR}/cetcli tx staking edit-validator --help
>
</details>


<details>
<summary>查询验证人节点状态:</summary>

*	Check your validator status in [CoinEx DEX Chain Explorer](https://explorer.coinex.org/validators)
	* 	测试网浏览器请查找[链接](https://github.com/coinexchain/testnets)

*	获取你的Validator的操作者地址

>	${RUN_DIR}/cetcli keys show ${KEY_NAME} --bech val

```
NAME:	TYPE:	ADDRESS:					
fullnode_user1	local	coinexvaloper1kg3e5p2rc2ejppwts6qwzrcgndvgeyztudujdz	
#coinexvaloper1kg3e5p2rc2ejppwts6qwzrcgndvgeyztudujdz is your validator operator address
```

*	查询链上的所有Validator

>	${RUN_DIR}/cetcli q staking validators --chain-id=${CHAIN_ID}
>

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

*	查询我设置的节点是否已处于`Validator` 角色

**注意：这条命令要求cetcli链接的cetd已经同步数据完成。**
**即：{RUN_DIR}/cetcli status 命令输出包含 "catching_up":false 时表示cetd已经同步完成**

>	${RUN_DIR}/cetcli q tendermint-validator-set --chain-id=${CHAIN_ID} | grep ${VALIDATOR_CONSENSUS_PUBKEY} <br>
>	&& echo "in validator set" || echo "not in validator set"<br>
>

输出`"in validator set"`时, 表示相关你的验证人节点已经建立完成.

</details>

-	1.9 将节点释放出监狱

当节点因为可用性差被关监狱时，可以使用下述命令，将节点释放出监狱.

`${RUN_DIR}/cetcli tx slashing unjail --from ${KEY_NAME} --chain-id=${CHAIN_ID} --gas=100000 --fees=2000000cet`

	

















