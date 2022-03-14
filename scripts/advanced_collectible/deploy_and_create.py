from scripts.helpful_scripts import (
    fund_with_link,
    get_account,
    OPENSEA_URL,
    get_contract,
    network,
    config,
)

from brownie import AdvancedCollectible


def deploy_and_create():
    # depending on the network, we will want to get the contracts on a testnet but if running local will need to deploy mocks
    account = get_account()
    advanced_collectible = AdvancedCollectible.deploy(
        get_contract("vrf_coordinator"),
        get_contract("link_token"),
        config["networks"][network.show_active()]["keyhash"],
        config["networks"][network.show_active()]["fee"],
        {"from": account},
    )
    # funding the contract with link tokens so that it can pay for the randomness services
    fund_with_link(advanced_collectible.address)
    creating_tx = advanced_collectible.createCollectible({"from": account})
    creating_tx.wait(1)
    print("new token has been created")
    return advanced_collectible, creating_tx


def main():
    deploy_and_create()
