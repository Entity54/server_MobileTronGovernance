Setting up tronGovernanceContract
Tron Governance Server is up on port 3000
tronGovernanceContract is set
currentBlockNumber: 31510274
queuePreparRefBlocks: [ 31378748, 31382956, 31437765 ]
queueActiveRefBlocks: [ 31187865, 31189788 ]
preparedReferenda: [ 3, 4, 5 ]
activeReferenda: [ 1, 2 ]
expiredReferenda: [ 0 ]
activeVoteTokens: []

Expect

minActiveRefBlockNum: null queueActiveRefBlocks: []
activeReferenda: [ ]
expiredReferenda: [ 0, 1, 2 ]

Expect

queuePreparRefBlocks: []
queueActiveRefBlocks: [ 31378748, 31382956, 31437765 ]
preparedReferenda: []
activeReferenda: [ 3, 4, 5 ]
expiredReferenda: [ 0, 1, 2 ]
activeVoteTokens: []

Expect

queuePreparRefBlocks: []
queueActiveRefBlocks: []
preparedReferenda: []
activeReferenda: []
expiredReferenda: [ 0, 1, 2, 3, 4, 5 ]
activeVoteTokens: []

{
"name": "tgs",
"version": "1.0.0",
"description": "Tron Governance Server",
"main": "index.js",
"dependencies": {
"async": "^2.6.1",
"config": "^1.31.0",
"cookie-parser": "~1.4.3",
"debug": "^3.1.0",
"dotenv": "^8.2.0",
"eventemitter2": "^5.0.1",
"express": "^4.14.0",
"hbs": "^4.0.0",
"http-errors": "~1.6.2",
"https-proxy-agent": "^2.2.1",
"lodash": "^4.17.10",
"mathjs": "^6.0.3",
"morgan": "~1.9.0",
"pako": "^1.0.6",
"pug": "2.0.0-beta11",
"request": "^2.88.2",
"socket.io": "^1.4.8",
"socks-proxy-agent": "^4.0.1",
"string-hash": "^1.1.3",
"superagent": "^5.1.0",
"url": "^0.11.0",
"tronweb": "^4.4.0"
},
"scripts": {
"test": "echo \"Error: no test specified\" && exit 1"
},
"author": "",
"license": "ISC"
}
