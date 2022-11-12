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
<br>

Server checks will start in 30secs
<br>

1 ====================> currentBlockNumber: 31513582 <==================== Sat Nov 12 2022 12:49:06 GMT+0200
(Eastern European Standard Time)
<br>
2 => minPreparedRefBlockNum: null queuePreparRefBlocks: []
<br>

3 => minActiveRefBlockNum: null queueActiveRefBlocks: []
<br>

4 => preparedReferenda: []
<br>

5 => activeReferenda: []
<br>

6 => expiredReferenda: [ 0, 1, 2, 3, 4, 5 ]
<br>

7 => activeVoteTokens: []
<br>

7.2 => No activeVoteTokens to check for unlocking
<br>

8.0.0 ==========> Checking currentBlockNumber > minActiveRefBlockNum
<br>

9.0.0 ==========> Checking currentBlockNumber > minPreparedRefBlockNum
<br>

End of checks currentBlockNumber: 31513582 minActiveRefBlockNum: null minPreparedRefBlockNum: null
