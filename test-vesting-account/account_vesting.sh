#!/bin/sh

DEX_DIR=/Users/fanzc/GolandProjects/dex
validator_name=validator-vest
chain_id=coinexdex-test1
fees=100000000cet
echo "####################################################### 分配给vesting-account账户2005w，锁仓2000w；解锁时间为5min之后"

#one million
test_amount=100000000000000cet
two_amount=200000000000000cet
six_amount=600000000000000cet

amount=2005000000000000cet
staking_amount=1500000000000000cet

twenty_million=2000000000000000cet
ten_million_int=1000000000000000

vesting_end_time=1571195700

cd ${DEX_DIR}
rm -rf ~/.cetcli ~/.cetd
bash ${DEX_DIR}/scripts/setup_single_testing_node.sh

cetcli keys add ${validator_name} <<<$'00000000\n00000000\n' &&
cetd add-genesis-account $(cetcli keys show ${validator_name} -a) ${amount} --vesting-amount=${twenty_million} --vesting-end-time=${vesting_end_time} --vesting-start-time=0 &&
rm ~/.cetd/config/gentx/*.json

echo "####################################################### vesting-account staking 1500w，账户剩余501w"
cetd gentx --amount=${staking_amount} --min-self-delegation=${ten_million_int} --name=${validator_name} <<<$'00000000\n' &&
cetd collect-gentxs &&
echo "####################################################### Collect-gentxs "

sed -i -e 's/1814400000000000/60000000000/g' ~/.cetd/config/genesis.json &&
cetd start > ./tmp.out &
echo "####################################################### Cetd start "
sleep 3


echo "####################################################### Issue token "
cetcli tx asset issue-token \
        --name="ABC Token" \
	    --symbol="abc" \
	    --total-supply=${ten_million_int} \
	    --mintable=true \
	    --burnable=true \
	    --addr-forbiddable=true \
	    --token-forbiddable=false \
	    --url="www.abc.org" \
	    --description="token abc is a example token" \
	    --identity="552A83BA62F9B1F8" \
        --from ${validator_name} --fees=${fees} --chain-id=${chain_id}
sleep 3

echo "####################################################### Create-trading-pair "
cetcli tx market create-trading-pair \
	    --stock=abc --money=cet \
	    --price-precision=8 \
        --from ${validator_name} --fees=${fees} --chain-id=${chain_id}
sleep 3

echo "####################################################### Send coins。 用户余额500w vesting未到期，转账 100w cet，转账失败"
cetcli tx send $(cetcli keys show bob -a) ${test_amount} --from ${validator_name} --fees=${fees} --chain-id=${chain_id}
sleep 3

echo "####################################################### Create-gte-order。用户余额500w vesting未到期，试图花费cet购买abc，下单失败"
cetcli tx market create-gte-order \
        --trading-pair=abc/cet \
        --side=1 --order-type=2 \
	    --price=100000000 --quantity=100000000000000 --price-precision=8 --identify=0 \
        --from ${validator_name} --fees=${fees} --chain-id=${chain_id}
sleep 3

echo "####################################################### Delegate。 用户余额500w vesting未到期，可以进行delegate，delegate 100w cet 成功"
cetcli tx staking delegate $(cetcli keys show ${validator_name} -a --bech val) ${test_amount} --from ${validator_name} --fees=${fees} --chain-id=${chain_id}
sleep 3

echo "####################################################### Unbond。 vesting未到期期间，用户可以进行staking Unbond，Unbond 200w cet 成功"
cetcli tx staking unbond $(cetcli keys show ${validator_name} -a --bech val) ${two_amount} --from ${validator_name} --fees=${fees} --chain-id=${chain_id}
sleep 3

echo "------------------------------------------------------- Wait Unbond time 60s to expire 此时用户余额600w vesting未到期，"

echo "####################################################### Send coins。用户余额600w vesting未到期，转账 600w cet，转账失败 "
cetcli tx send $(cetcli keys show bob -a) ${six_amount} --from ${validator_name} --fees=${fees} --chain-id=${chain_id}
sleep 3

echo "####################################################### Send coins。用户余额600w vesting未到期，转账 100w cet，转账失败 "
cetcli tx send $(cetcli keys show bob -a) ${test_amount} --from ${validator_name} --fees=${fees} --chain-id=${chain_id}
sleep 3

echo "####################################################### Create-gte-order。用户余额600w vesting未到期，试图花费cet购买abc，下单失败"
cetcli tx market create-gte-order \
        --trading-pair=abc/cet \
        --side=1 --order-type=2 \
	    --price=100000000 --quantity=100000000000000 --price-precision=8 --identify=0 \
        --from ${validator_name} --fees=${fees} --chain-id=${chain_id}
sleep 3

echo "------------------------------------------------------- Wait Vesting time to expire "


echo "####################################################### Send coins。vesting到期，可以转账"
cetcli tx send $(cetcli keys show bob -a) ${test_amount} --from ${validator_name} --fees=${fees} --chain-id=${chain_id}
sleep 3

echo "####################################################### Create-gte-order。 vesting到期，可以下单"
cetcli tx market create-gte-order \
        --trading-pair=abc/cet \
        --side=1 --order-type=2 \
	    --price=100000000 --quantity=100000000000000 --price-precision=8 --identify=0 \
        --from ${validator_name} --fees=${fees} --chain-id=${chain_id}
sleep 3
