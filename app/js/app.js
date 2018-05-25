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


        contract.methods.numArtists().call()
        .then(function(num){
          console.log('num artists '+ num);
          for (var i = 0; i < num; i++){
            contract.methods.artistToAddresses(i).call()
            .then(function(addresses){
              console.log('addresses '+ addresses);

            })
          }
        })



    })
    .catch(console.error);

    function registerArtist(_name, count, minPrice, totalEth) {
        contract.methods.registerArtist(web3.utils.fromAscii(_name), count, minPrice).send({from: userAccount, value: totalEth + 1000, gas: 6385876})
        .then(function (name) {
            console.log(name + 'has successfully been created');
            if (_name === 'Pitbull'){
              var div = document.createElement('div');
              div.className += 'col s12 m4';
              div.innerHTML = "<div class='card purple darken-3'><div class='card-content white-text'><span class='card-title'>Pitbull</span><p>Token ID: 13311</p><p>Price: 1.2 ETH</p><p>Quantity: 38</p></div><div class='card-action'><a href='#'>Buy</a></div></div>"
              document.getElementById('pitbull').appendChild(div);
            }
        }).catch(function (e) {
          console.log(web3.utils.fromAscii(_name));
          console.log(totalEth); // msg.value
          console.log(count*20000000000000); //
          console.log(e);
        });
    }
    function bahamas(){
      M.toast({html: 'You just redeemed a free holiday at the Bahamas with Pitbull!'})
    }

    $("#createMyToken").click(function() {
        var artist_name = $("#artist_name").val();
        var tokenCount = $("#tokenCount").val();
        var price = $("#price").val() * 1000000000000000000;
        var totalEth = tokenCount * 20000000000000;
        registerArtist(artist_name, tokenCount, price, totalEth);
        $("#artist_name").val("");
        $("#tokenCount").val("");
        $("#price").val("");
    });

    function func(){
      M.toast({html: 'You just redeemed a free holiday at the Bahamas with Pitbull!'})
      $("#getrid").remove();
    }

    $("#redeem").click(function() {
        var artist_name = 'lol';
        var tokenCount = 2;
        var price = 0.001 * 1000000000000000000;
        var totalEth = tokenCount * 20000000000000;
        registerArtist(artist_name, tokenCount, price, totalEth);
        setTimeout(func, 6000);

    });

  $( "#redeem2" ).click(function(event) {
    $(this).closest("tr").remove();
    console.log("clicked redeem");
});

$( "#redeem3" ).click(function(event) {
  $(this).closest("tr").remove();
  console.log("clicked redeem");
});

}

$(document).ready(app);
