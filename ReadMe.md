This is a webserver for keeping the MobileTornGovernance Smart contract up to date with
<br>
Checks Preparerd Referenda that can be moved to Active Referenda and start voting
<br>
Checks Active Referenda that have expired and need to be moved to Expired Referenda
<br>
Checks for Vote Tokens that can be unlocked
<br>
<br>

Example output
Server checks will start in 30secs
1 ====================> currentBlockNumber: 31513582 <==================== Sat Nov 12 2022 12:49:06 GMT+0200 (Eastern European Standard Time)
2 => minPreparedRefBlockNum: null queuePreparRefBlocks: []
3 => minActiveRefBlockNum: null queueActiveRefBlocks: []
4 => preparedReferenda: []
5 => activeReferenda: []
6 => expiredReferenda: [ 0, 1, 2, 3, 4, 5 ]
7 => activeVoteTokens: []
7.2 => No activeVoteTokens to check for unlocking
8.0.0 ==========> Checking currentBlockNumber > minActiveRefBlockNum
9.0.0 ==========> Checking currentBlockNumber > minPreparedRefBlockNum
End of checks currentBlockNumber: 31513582 minActiveRefBlockNum: null minPreparedRefBlockNum: null
