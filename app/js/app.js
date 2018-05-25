function app() {
    if (typeof web3 == 'undefined') throw 'No web3 detected. Is Metamask/Mist being used?';
    web3 = new Web3(web3.currentProvider); // MetaMask injected Ethereum provider
    console.log("Using web3 version: " + Web3.version);

    var contract;
    var userAccount;

    var contractDataPromise = $.getJSON('ArtistTokenContract.json');
    var networkIdPromise = web3.eth.net.getId(); // resolves on the current network id
    var accountsPromise = web3.eth.getAccounts(); // resolves on an array of accounts

    Promise.all([contractDataPromise, networkIdPromise, accountsPromise])
      .then(function initApp(results) {
        var contractData = results[0];  // resolved value of contractDataPromise
        var networkId = results[1];     // resolved value of networkIdPromise
        var accounts = results[2];      // resolved value of accountsPromise
        userAccount = accounts[0];

        // Make sure the contract is deployed on the network to which our provider is connected
        console.log(contractData.networks)
        console.log(networkId)
        if (!(networkId in contractData.networks)) {
           throw new Error("Contract not found in selected Ethereum network on MetaMask.");
        }

        var contractAddress = contractData.networks[networkId].address;
        contract = new web3.eth.Contract(contractData.abi, contractAddress);
    })
    // .then(showUserDetails)
    .catch(console.error);

    // function showUserDetails() {
    //     contract.methods.withdrawAmount(userAccount).call().then(function (total) {
    //         $('#withdrawDetails').text(web3.utils.fromWei(total, "ether") + " ETH withdrawable");
    //    });
    // }

    function registerArtist(_name, count, minPrice, totalEth) {
        contract.methods.registerArtist(web3.utils.fromAscii(_name), count, minPrice).send({from: userAccount, value: totalEth, gas: 250000})
        .then(function (name) {
            console.log(name + 'has successfully been created');
        }).catch(function (e) {
          console.log(e);
        });
    }
    //
    //     contract.methods.poolCreator(poolId).call()
    //     .then(function (creator) {
    //         console.log(creator)
    //         $('#poolDetails2').text('Created by: ' + creator);
    //         $('#pool1Details2').text('Created by: ' + creator);
    //     })
    //
    //     contract.methods.totalInvestmentForPool(poolId).call()
    //     .then(function (total) {
    //         var amount = web3.utils.fromWei(total, "ether");
    //         console.log(amount);
    //         $("#poolDetails3").text('Total amount: ' + amount + ' ETH');
    //         $("#pool1Details3").text('Total amount: ' + amount + ' ETH');
    //     })
    //
    //     contract.methods.getInvestmentByUser(poolId, userAccount).call()
    //     .then(function (amount) {
    //         var investment = web3.utils.fromWei(amount, "ether");
    //         console.log(investment)
    //         $("#investmentDetails").text('Your investment: ' + investment + ' ETH');
    //         $("#investment1Details").text('Your investment: ' + investment + ' ETH');
    //     })
    //  }


    $("#createMyToken").click(function() {
        var artist_name = $("#artist_name").val();
        var tokenCount = $("#tokenCount").val();
        var price = $("#price").val() * 1000000000000000000;
        var totalEth = tokenCount * 20000000000000;
        console.log(artist_name);
        console.log(tokenCount);
        console.log(price);
        console.log(totalEth);
        registerArtist(artist_name, tokenCount, price, totalEth);
    });
}

$(document).ready(app);
