'use strict';
require('dotenv').config();
const express = require('express');
const path = require('path');             
const http = require('http');     
const TronWeb = require('tronweb');


const TronGovernance_raw = require('./Abis/tronGovernance.json');     
const tronGovernance_ABI = TronGovernance_raw.abi;
// ****************************************************************************
const tronGovernanceContractAddress = "TBHLsbmX2mhSyWjXdh1fciCmHNbXHca8Yy";
// ****************************************************************************
let tronWeb, tronGovernanceContract, counter = 0;

const publicKey = process.env.TronGovernanceServer_PUBLICKEY;
const privateKey = process.env.TronGovernanceServer_PRIVATEKEY;
console.log(`publicKey: ${publicKey} privateKey: ${privateKey}`);


const updateTronWeb = () => {
    console.log(`Tron Governance Server Setting Up HttpProvider`);
    const HttpProvider = TronWeb.providers.HttpProvider;
    const fullNode = new HttpProvider("https://api.nileex.io");
    const solidityNode = new HttpProvider("https://api.nileex.io");
    const eventServer = new HttpProvider("https://api.nileex.io");
    tronWeb = new TronWeb(fullNode,solidityNode,eventServer,privateKey);
    console.log(`TronWeb is now ready`);
}


const publicPath = path.join(__dirname,'./');       

const port = process.env.PORT || 3000;
var app = express();

app.use((req,res,next) => {
    next();
});
 
const server = http.createServer(app); 
app.use(express.static(publicPath)); 


console.log(`${new Date()} **** Server is up and running ****`);
const startServer = async () => {

  console.log(`Setting up tronWeb`); 
  updateTronWeb();
  console.log(`Setting up tronGovernanceContract`); 
  tronGovernanceContract = await tronWeb.contract(tronGovernance_ABI, tronGovernanceContractAddress);
  console.log('tronGovernanceContract is set');
  

  const startProcess = async () => {

        //Get current block number
        const currentBlock = await tronWeb.trx.getCurrentBlock();
        const currentBlockNumber = Number(`${currentBlock.block_header.raw_data.number}`);
        console.log('1 ====================> currentBlockNumber: ',currentBlockNumber,` <==================== ${new Date()} `);

        // *** Get block numbers tha PreparedReferendaId jump to Active Referenda ***
        //logic: if current blocknumber  >= of any of the block above then find refrendaId from preparedReferenda to move to ActiveReferenda
        let queuePreparRefBlocks  = await tronGovernanceContract.getQueuePreparRefBlocks().call();
        queuePreparRefBlocks = queuePreparRefBlocks.map(item => Number(`${item}`));
        const minPreparedRefBlockNum = queuePreparRefBlocks.length>0? Math.min(...queuePreparRefBlocks) : null;
        console.log(`2 => minPreparedRefBlockNum: ${minPreparedRefBlockNum} queuePreparRefBlocks: `,queuePreparRefBlocks);  // queuePreparRefBlocks:  [ 31378748, 31382956, 31437765 ]

        // ****** Get block numbers that Active Referenda jump to Expired Referend ******
        //logic: if current blocknumber  >= of any of the block above then find refrendaId from activeReferenda to move to ExpiredReferenda
        let queueActiveRefBlocks  = await tronGovernanceContract.getQueueActiveRefBlocks().call();
        queueActiveRefBlocks = queueActiveRefBlocks.map(item => Number(`${item}`));
        const minActiveRefBlockNum = queueActiveRefBlocks.length>0? Math.min(...queueActiveRefBlocks) : null;
        console.log(`3 => minActiveRefBlockNum: ${minActiveRefBlockNum} queueActiveRefBlocks: `,queueActiveRefBlocks);  // queueActiveRefBlocks:  [ 31187865, 31189788 ]

        // |>Get Prepared Referenda IDs<|
        let preparedReferenda  = await tronGovernanceContract.getPreparedReferenda().call();
        preparedReferenda = preparedReferenda.map(item => Number(`${item}`));
        console.log(`4 => preparedReferenda: `,preparedReferenda);  //preparedReferenda:  [ 3, 4, 5 ]

        // ||>>Get Active Referenda IDs<<||
        let activeReferenda  = await tronGovernanceContract.getActiveReferenda().call();
        activeReferenda = activeReferenda.map(item => Number(`${item}`));
        console.log(`5 => activeReferenda: `,activeReferenda); //activeReferenda:  [ 1, 2 ]

        //Get |||>>>Expired Referenda IDs<<<|||
        let expiredReferenda  = await tronGovernanceContract.getExpiredReferenda().call();
        expiredReferenda = expiredReferenda.map(item => Number(`${item}`));
        console.log(`6 => expiredReferenda: `,expiredReferenda); //expiredReferenda:  [ 0 ]

        // ***> Get Active Vote Tokens <***
        let activeVoteTokens  = await tronGovernanceContract.getActiveVoteTokens().call();
        // expiredReferenda = expiredReferenda.map(item => Number(`${item}`));
        console.log(`7 => activeVoteTokens: `,activeVoteTokens); //activeVoteTokens:  []

        if (activeVoteTokens.length > 0)
        {
          console.log(`7.1.1 => There are activeVoteTokens activeVoteTokens.length: ${activeVoteTokens.length}. Will now check if can be unlocked`);
          let result1 = await tronGovernanceContract.unlockVoteTokens().send({
            feeLimit:100000000,
            callValue: 0,
            shouldPollResponse:true
          });
          console.log(`7.1.2 => unlockVoteTokens has been updated`);
        } else console.log(`7.2 => No activeVoteTokens to check for unlocking`);

        
        console.log(`8.0.0 ==========> Checking currentBlockNumber > minActiveRefBlockNum `);
        if (minActiveRefBlockNum && currentBlockNumber > minActiveRefBlockNum)  //some active referenda have expired
        {
            console.log(`8.1.0 => **** At Block Number: ${currentBlockNumber} found that minActiveRefBlockNum: ${minActiveRefBlockNum} and some Active Referenda have expired and need to update updateQueueActiveRefBlocks and updateActiveReferenda`);
            let result1 = await tronGovernanceContract.updateQueueActiveRefBlocks().send({
              feeLimit:100000000,
              callValue: 0,
              shouldPollResponse:true
            });
            console.log(`8.1.1 => updateQueueActiveRefBlocks has been updated`);
      
            console.log(`8.2.0 => Time to run updateActiveReferenda`);
            let result2 = await tronGovernanceContract.updateActiveReferenda().send({
              feeLimit:100000000,
              callValue: 0,
              shouldPollResponse:true
            });
            console.log(`8.2.1 => updateActiveReferenda has been updated`);
      
        }


        console.log(`9.0.0 ==========> Checking currentBlockNumber > minPreparedRefBlockNum `);
        if (minPreparedRefBlockNum && currentBlockNumber > minPreparedRefBlockNum)  //some active referenda have expired
        {
            console.log(`9.1.0 => **** At Block Number: ${currentBlockNumber} found that minPreparedRefBlockNum: ${minPreparedRefBlockNum} and some Prepared Referenda have to be moved to Active Referenda and need to update updateQueuePreparRefBlocks and updatePreparedReferenda`);
            let result1 = await tronGovernanceContract.updateQueuePreparRefBlocks().send({
              feeLimit:100000000,
              callValue: 0,
              shouldPollResponse:true
            });
            console.log(`9.1.1 => updateQueuePreparRefBlocks has been updated`);
      
            console.log(`9.2.0 => Time to run updatePreparedReferenda`);
            let result2 = await tronGovernanceContract.updatePreparedReferenda().send({
              feeLimit:100000000,
              callValue: 0,
              shouldPollResponse:true
            });
            console.log(`9.2.1 => updatePreparedReferenda has been updated`);
      
        }


        console.log(`End of checks currentBlockNumber: ${currentBlockNumber} minActiveRefBlockNum: ${minActiveRefBlockNum} minPreparedRefBlockNum: ${minPreparedRefBlockNum}`);
        
  }  


  // setTimeout(() => {
  console.log(`Server checks will start in 30secs`); 
  setInterval(() => {
    startProcess()
  },30000);

}
startServer();


server.listen(port, () => {
  console.log(`Tron Governance Server is up on port ${port}`);
});