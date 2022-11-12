// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./treasury.sol";

contract tronGovernance {
    uint256 public band1 = 100 * 1e6; //up for project Governance Token
    uint256 public band2 = 500 * 1e6; //up for project Governance Token
    uint256 public band3 = 1000 * 1e6; //up for project Governance Token
    uint256 public band1_ScoreThreshold = 25; //up for project Governance Token
    uint256 public band2_ScoreThreshold = 55; //up for project Governance Token
    uint256 public band3_ScoreThreshold = 65; //up for project Governance Token
    uint256 public refrendumFee = 10 * 1e6; //up for project Governance Token

    enum REFERENDUMSTATE {
        INACTIVE,
        ACTIVE,
        EXPIRED
    }
    address public admin;
    uint256 public referendumIndex;

    uint256[] public preparedReferenda;
    uint256[] public queuePreparRefBlocks; //the blocks that checks need to be run
    // mapping(uint => uint) public preparedReferendumLoc;  //referendumIndex => index in preparedReferenda
    uint256[] public activeReferenda;
    uint256[] public queueActiveRefBlocks; //the blocks that checks need to be run
    // mapping(uint => uint) public activeReferendumLoc;    //referendumIndex => index in activeReferenda
    uint256[] public expiredReferenda;
    mapping(uint256 => REFERENDUMSTATE) public referendumIsActive;

    struct referendum {
        uint256 index;
        address beneficier;
        address treasuryAddress;
        uint256 amount;
        string referendumCID;
        uint256 startBlock;
        uint256 endBlock;
        uint256 scoreBlocknum;
        uint256 votesAye;
        uint256 votesNay;
        uint256 turnount;
        bool passed;
    }

    mapping(uint256 => referendum) public referendumDetails;

    //Beneficiary
    mapping(address => bool) public referendumBeneficiary;
    mapping(address => uint256) public beneficiaryScore;

    //Treasuries
    uint256 public treasurerBalanceThreshold = 1100; //sun //up for project Governance Token TodoChange this to 1100 Tron
    address[] public treasurers;
    mapping(address => bool) public isTreasurer;

    //Voters
    mapping(uint256 => mapping(address => bool)) public isVoterOfReferendum;
    mapping(uint256 => uint256) public convictionLockedBlocks;
    mapping(uint256 => uint256) public convictionMultiplier;

    struct voteToken {
        uint256 unlockBlockNum;
        uint256 amount;
        address voteOwner;
    }
    voteToken[] public activeVoteTokens;
    mapping(address => uint256) public voterClaimableAmount;

    event newReferendumCreated(
        uint256 index,
        address beneficiary,
        uint256 amount,
        uint256 startBlock,
        address treasuryAddress
    );
    event newTreasuryLaunched(
        address admin,
        address newTreasuryAddress,
        uint256 initialFunds
    );
    event newVoteEvent(
        uint256 refIndex,
        address voter,
        uint256 numTokens,
        uint256 totalValue,
        bool aye,
        uint256 convction
    );

    constructor() {
        admin = msg.sender;
        convictionLockedBlocks[1] = 10;
        convictionLockedBlocks[2] = 20;
        convictionLockedBlocks[3] = 30;
        convictionMultiplier[0] = 1;
        convictionMultiplier[1] = 2;
        convictionMultiplier[2] = 3;
        convictionMultiplier[3] = 4;
    }

    function launchNewTreasury() external payable {
        require(
            msg.value >= treasurerBalanceThreshold,
            "launching treasury requires TRX"
        );
        Treasury newTreasurer = new Treasury(msg.sender);
        address newTreasuryAddress = address(newTreasurer);
        payable(newTreasuryAddress).transfer(msg.value - 100);
        isTreasurer[newTreasuryAddress] = true;
        treasurers.push(newTreasuryAddress);
        emit newTreasuryLaunched(msg.sender, newTreasuryAddress, msg.value);
    }

    function referendumBeneficiaryIsEntitled(address benef, uint256 amount)
        public
        view
        returns (bool)
    {
        bool entitled;
        uint256 score = beneficiaryScore[benef];
        if (amount >= band3) {
            entitled = score >= band3_ScoreThreshold ? true : false;
        } else if (amount >= band2) {
            entitled = score >= band2_ScoreThreshold ? true : false;
        } else if (amount >= band1) {
            entitled = score >= band1_ScoreThreshold ? true : false;
        }

        return entitled;
    }

    function createNewReferendum(
        address _treasuryAddress,
        uint256 _amount,
        string memory _referendumCID,
        uint256 startInNumBlocks,
        uint256 duration,
        uint256 scoreInNumBlocks
    ) external payable {
        require(
            msg.value >= refrendumFee,
            "need to pay at least refrendumFee to create a new referendum"
        );

        if (!referendumBeneficiary[msg.sender]) {
            referendumBeneficiary[msg.sender] = true;
            beneficiaryScore[msg.sender] = 50;
        }

        require(
            referendumBeneficiaryIsEntitled(msg.sender, _amount),
            "beneficiary score too low for this amount"
        );
        require(
            isTreasurer[_treasuryAddress],
            "treasury address passed is not a treasurer"
        );
        require(
            _treasuryAddress.balance >= (_amount + treasurerBalanceThreshold),
            "treasurer does not have enough funds"
        );
        require(
            startInNumBlocks <= 20,
            "startInNumBlocks must be less than 20"
        );
        require(
            duration >= 20 && duration <= 201600,
            "duration must be <=201600 n >=20"
        );

        uint256 startBlok = block.number + startInNumBlocks;
        referendum memory newReferendum = referendum({
            index: referendumIndex,
            beneficier: msg.sender,
            treasuryAddress: _treasuryAddress,
            amount: _amount,
            referendumCID: _referendumCID,
            startBlock: startBlok,
            endBlock: startBlok + duration,
            scoreBlocknum: startBlok + duration + scoreInNumBlocks,
            votesAye: 0,
            votesNay: 0,
            turnount: 0,
            passed: false
        });

        // preparedReferendumLoc[referendumIndex] = preparedReferenda.length;
        preparedReferenda.push(referendumIndex);
        referendumDetails[referendumIndex] = newReferendum;
        referendumIsActive[referendumIndex] = REFERENDUMSTATE.INACTIVE;

        queuePreparRefBlocks.push(startBlok); //used to avoid backlogging

        emit newReferendumCreated(
            referendumIndex,
            msg.sender,
            _amount,
            (block.number + startInNumBlocks),
            _treasuryAddress
        );

        referendumIndex++;
    }

    function voteReferendum(
        uint256 referendumID,
        bool isAye,
        uint256 conviction
    ) external payable {
        require(
            referendumIsActive[referendumID] == REFERENDUMSTATE.ACTIVE,
            "referednum is not active"
        );
        require(
            !isVoterOfReferendum[referendumID][msg.sender],
            "address already voted for this referendum"
        );
        require(conviction >= 0 && conviction < 4, "conviction out of range");

        uint256 voteValue = msg.value * convictionMultiplier[conviction];
        if (isAye) {
            referendumDetails[referendumID].votesAye += voteValue;
        } else {
            referendumDetails[referendumID].votesNay += voteValue;
        }

        isVoterOfReferendum[referendumID][msg.sender] = true;
        referendumDetails[referendumID].turnount += 1;

        voteToken memory newVoteToken = voteToken({
            unlockBlockNum: referendumDetails[referendumID].endBlock +
                convictionLockedBlocks[conviction],
            amount: msg.value,
            voteOwner: msg.sender
        });
        activeVoteTokens.push(newVoteToken);

        emit newVoteEvent(
            referendumID,
            msg.sender,
            msg.value,
            voteValue,
            isAye,
            conviction
        );
    }

    function unlockVoteTokens() external {
        uint256 i = 0;
        while (i < activeVoteTokens.length) {
            if (block.number > activeVoteTokens[i].unlockBlockNum) {
                voterClaimableAmount[
                    activeVoteTokens[i].voteOwner
                ] += activeVoteTokens[i].amount;
                if (i < activeVoteTokens.length - 1) {
                    activeVoteTokens[i] = activeVoteTokens[
                        activeVoteTokens.length - 1
                    ];
                } else {
                    i++;
                }
                activeVoteTokens.pop();
            } else {
                i++;
            }
        }
    }

    function withdrawVoteTokens() external {
        uint256 claimableAmount = voterClaimableAmount[msg.sender];
        if (claimableAmount > 0) {
            voterClaimableAmount[msg.sender] = 0;
            payable(msg.sender).transfer(claimableAmount);
        }
    }

    function updatePreparedReferenda() external {
        uint256 i = 0;
        while (i < preparedReferenda.length) {
            uint256 prepareReferendaId = preparedReferenda[i];
            if (
                block.number > referendumDetails[prepareReferendaId].startBlock
            ) {
                if (i < preparedReferenda.length - 1) {
                    preparedReferenda[i] = preparedReferenda[
                        preparedReferenda.length - 1
                    ];
                } else {
                    i++;
                }
                preparedReferenda.pop();
                activeReferenda.push(prepareReferendaId);
                referendumIsActive[prepareReferendaId] = REFERENDUMSTATE.ACTIVE;

                uint256 endBlock = referendumDetails[prepareReferendaId]
                    .endBlock;
                queueActiveRefBlocks.push(endBlock); //used to avoid backlogging
            } else {
                i++;
            }
        }
    }

    function updateActiveReferenda() external {
        uint256 i = 0;
        while (i < activeReferenda.length) {
            uint256 activeReferendaId = activeReferenda[i];
            if (block.number > referendumDetails[activeReferendaId].endBlock) {
                if (i < activeReferenda.length - 1) {
                    activeReferenda[i] = activeReferenda[
                        activeReferenda.length - 1
                    ];
                } else {
                    i++;
                }
                activeReferenda.pop();

                //add it to expired referenda
                expiredReferenda.push(activeReferendaId);
                referendumIsActive[activeReferendaId] = REFERENDUMSTATE.EXPIRED;

                //pay beneficiary
                // referendum memory refrnd = referendumDetails[activeReferendaId];

                if (
                    referendumDetails[activeReferendaId].votesAye >
                    referendumDetails[activeReferendaId].votesNay
                ) {
                    address trsrAddress = referendumDetails[activeReferendaId]
                        .treasuryAddress;
                    Treasury treasr = Treasury(payable(trsrAddress));
                    treasr.sendTransfer(
                        referendumDetails[activeReferendaId].beneficier,
                        referendumDetails[activeReferendaId].amount
                    );
                    referendumDetails[activeReferendaId].passed = true;
                }
            } else {
                i++;
            }
        }
    }

    function scoreBeneficiary(
        address treasuryAddress,
        uint256 refIndex,
        uint256 score
    ) external {
        require(score >= 0 && score <= 100, "score range is 0 to 100");
        Treasury treasuryGrader = Treasury(payable(treasuryAddress));
        require(
            msg.sender == treasuryGrader.admin(),
            "must be admin of the treasury to score"
        );

        referendum memory refrnd = referendumDetails[refIndex];
        require(
            refrnd.treasuryAddress == treasuryAddress,
            "not treasurer of referendumIndex"
        );
        require(block.number > refrnd.scoreBlocknum, "scoring not allowed yet");
        address beneficiary = refrnd.beneficier;
        beneficiaryScore[beneficiary] =
            (beneficiaryScore[beneficiary] + score) /
            2;
    }

    function updateQueuePreparRefBlocks() external {
        uint256 i = 0;
        while (i < queuePreparRefBlocks.length) {
            uint256 queuePreparRefBlocksId = queuePreparRefBlocks[i];
            if (block.number > queuePreparRefBlocksId) {
                if (i < queuePreparRefBlocks.length - 1) {
                    queuePreparRefBlocks[i] = queuePreparRefBlocks[
                        queuePreparRefBlocks.length - 1
                    ];
                } else {
                    i++;
                }
                queuePreparRefBlocks.pop();
            } else {
                i++;
            }
        }
    }

    function updateQueueActiveRefBlocks() external {
        uint256 i = 0;
        while (i < queueActiveRefBlocks.length) {
            uint256 queueActiveRefBlocksId = queueActiveRefBlocks[i];
            if (block.number > queueActiveRefBlocksId) {
                if (i < queueActiveRefBlocks.length - 1) {
                    queueActiveRefBlocks[i] = queueActiveRefBlocks[
                        queueActiveRefBlocks.length - 1
                    ];
                } else {
                    i++;
                }
                queueActiveRefBlocks.pop();
            } else {
                i++;
            }
        }
    }

    function getQueuePreparRefBlocks() public view returns (uint256[] memory) {
        return queuePreparRefBlocks;
    }

    function getQueueActiveRefBlocks() public view returns (uint256[] memory) {
        return queueActiveRefBlocks;
    }

    function getActiveReferenda() public view returns (uint256[] memory) {
        return activeReferenda;
    }

    function getPreparedReferenda() public view returns (uint256[] memory) {
        return preparedReferenda;
    }

    function getExpiredReferenda() public view returns (uint256[] memory) {
        return expiredReferenda;
    }

    function getTreasurers() public view returns (address[] memory) {
        return treasurers;
    }

    function getActiveVoteTokens() public view returns (voteToken[] memory) {
        return activeVoteTokens;
    }
}
