
if(typeof web3 === 'undefined')
    web3 = new Web3(new Web3.providers.HttpProvider('http://localhost:8545'));

var transferToManyABI = [{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"_addr","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_addrs","type":"address[]"},{"name":"_amounts","type":"uint256[]"}],"name":"transferToMany","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"}];

var currAccount;
var TTMContract = web3.eth.contract(transferToManyABI);
var tokenAddress;
var totalTokens;
var tokenContract = TTMContract.at(tokenAddress);
var validList = [];
var invalidList = [];
var decShift = 1;

var maxBatch = 100;
var batches = [];
var gasEstimate = 0;
var txReceipts = {};

function $id(eId) {
    return document.getElementById(eId);
}

function getAccounts() {
    accs = web3.eth.accounts;
    currAccount = accs[0];
    opts = "";
    for(let i=0; i < accs.length; i++) {
        opts += `<option class="mono" value="${accs[i]}">${accs[i]}</option>`
    }
    $id("accounts").innerHTML = opts;
    $id("eth-bal").innerText = `${web3.fromWei(web3.eth.getBalance(currAccount)).toFormat(6)} eth`;
}

function ethBal(e) {
    setAccount(e.target.value);
    $id("eth-bal").innerText = `${web3.fromWei(web3.eth.getBalance(currAccount)).toFormat(6)} eth`;
    tokBal();
}

function tokBal() {
    acc = $id("accounts").value;
    tokenBal = tokenContract.balanceOf(acc).div(decShift).toFormat(6);
    $id("tok-bal").innerText = `${tokenBal} Tokens`;
    if (tokenBal < totalTokens) {
        $id("bat-button").disabled = true;
        $id("insuf-tokens").innerText = "Insufficient token balance";
    } else {
        $id("bat-button").disabled = false;  
        $id("insuf-tokens").innerText = "";              
    }
}

function setAccount(acc) {
    currAccount = acc;
}

function setAddress(e) {
    csa = web3.toChecksumAddress(e.target.value);
    e.target.value = csa;
    if(web3.isAddress(csa) && csa.length == 42) {
        tokenContract = TTMContract.at(csa);
        decShift = 10**tokenContract.decimals() || 1;
        tokBal();
        $id('tables').hidden = false;
    }
}

function setMaxBatch(event) {
    maxBatch = event.target.value;
    if (validList) {
        buildValid(validList);
    }
}

function importJson(e) {
    var fp = e.target.files[0];
    var reader = new FileReader();
    reader.onload = function (e) {
        validateList(JSON.parse(e.target.result));
        buildInvalid(invalidList);
        buildValid(validList);
    };

    if (!fp) { return; }
    $id("filename").innerText = fp.name;
    reader.readAsText(fp);
}

function validateList(list) {
    var r, i = 0;
    totalTokens = 0;
    for(i; i < list.length; i++) {
        r = list[i];
        if (web3.isAddress(r.address)) {
            validList.push({row: i, address: r.address, tokens: r.tokens});
            totalTokens += Number(r.tokens)/decShift;
        } else {
            invalidList.push({row: i, address: r.address, tokens: r.tokens});            
        }
    }
}

function buildInvalid(list) {
    let rows = "";
    var i = 0;
    if(list.length > 0) { $id("invalids").hidden = false; }

    list.forEach((r)=> {
        rows += `<tr class="mono">
            <td>${r.row}</td>
            <td>${r.address}</td>
            <td>${r.tokens}</td>
        </tr>
        `;}
    );
    $id("invalid-list").innerHTML = rows;
}

function buildValid(list) {
    var i = 0, b = -1;
    if(list.length > 0) { $id("valids").hidden = false; } 
    $id("gas-estimate").innerText = "estimating...";
    getBatches(list);
    let ulInner = "";

    for (i; i < list.length; i++) {
        if (i % maxBatch == 0) b++;
        r = list[i];
        ulInner += `<tr class="mono">
            <td>${b}</td>
            <td>${r.row}</td>
            <td>${r.address}</td>
            <td>${r.tokens}</td>
        </tr>
        `;
    }
    $id("addr-list").innerHTML = ulInner;
    $id("gas-estimate").innerText = `${gasEstimate.toLocaleString()} gas (estimated)`;
    $id("total-tokens").innerText = `${totalTokens} Total token transfer`;
}

function getBatches(list) {
    var i = 0, b = 0;
    batches = [[[],[]]];
    gasEstimate = 0;

    for (i; i < list.length; i++) {
        if(!web3.isAddress(list[i].address)) {
            console.log(`Invalid address: ${list[i].address}`);
            continue;
        }

        if (i % maxBatch == 0) {
            // Batch boundary
            gasEstimate += tokenContract.transferToMany.estimateGas(batches[b][0],batches[b][1]);
            b++;
            batches.push([[],[]]);
        }
        batches[b][0].push(list[i].address);
        batches[b][1].push(list[i].tokens);
    }
    $id("bat-button").disabled = false;
    return batches;
}

function runBatches() {
    var i = 0;
    $id("receipts").hidden = false;
    $id("tx-list").innerHTML = "";

    txBatch = web3.createBatch();
    
    for(i; i < batches.length; i++) {
        let bNum = i
        txBatch.add(
            tokenContract.transferToMany(
                batches[i][0],
                batches[i][1],
                {
                    from:web3.eth.accounts[0],
                    gas:3000000,
                    gasPrice:100000000
                },
                (err, recipt) => { txcb(err, recipt, bNum); }
            )
        )
        console.log(`batch ${i} ${txBatch.requests[i]}`);        
    }
    txBatch.execute();
}

function txcb(e, receipt, batchNum){
    console.log(e, receipt);
    if(e) {
        txErr(e);
    }

    if (typeof receipt !== 'undefined') {
        txReceipts[receipt] = {
            batchNum: batchNum,
            itvlId: setInterval(()=>{txWait(receipt, txrReport)}, 1000)
        }
        txLodge(receipt, batchNum);
        // txReceipts[receipt] = setInterval(()=>{txWait(receipt, txrReport)}, 500);
    }
}

function txWait(receipt, cb) {
    txr = web3.eth.getTransaction(receipt);
    if (txr.blockNumber != null) {
        console.log(`TX ${receipt} mined in block: ${txr.blockNumber}`);
        clearInterval(txReceipts[receipt].itvlId);
        delete txReceipts[receipt].itvlId;
        cb(receipt);
    }
}

function txLodge(receipt, batchNum) {
    var txList = $id("tx-list");
    var txTr = document.createElement("tr");
    txTr.classList.add("mono");
    txTr.innerHTML = `<td>${batchNum}</td>
        <td><a href="https://etherscan.io/tx/${receipt}">${receipt}</a></td>
        <td class="pure-u-1-5" id=${receipt}>waiting...</td>
        `;
    txList.appendChild(txTr);
}

function txrReport(receipt) {
    var txr = web3.eth.getTransaction(receipt);
    var txTd = $id(receipt);
    txReceipts[receipt].receipt = txr;
    txTd.innerHTML = `mined in block ${txr.blockNumber}`;
}

function txErr(e) {
    console.log(e);
    var txList = $id("tx-list");
    var txDiv = document.createElement("div");
    txDiv.innerHTML = `<span>${e}</span>`
    txList.appendChild(txDiv);
}

function exportReceipts() {
    var anch =  document.createElement('a');
    var stringData = 'data:application/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(txReceipts));
    anch.href = stringData;
    anch.target = '_blank';
    anch.download = "transferToMany_rcpts.json";
    anch.click();
    anch.remove();
}