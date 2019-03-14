pragma solidity ^0.4.23;
import "RoundBasedGame.sol";
import "SafeMath.sol";


contract Baccarat is RoundBasedGame {
    using SafeMath for *;

    uint8 constant private CARD_COUNT = 52;
    uint8 constant private BET_BANKER_WIN = 1;
    uint8 constant private BET_PLAYER_WIN = 2;
    uint8 constant private BET_TIE = 4;
    uint8 constant private BET_BANKER_PAIR = 8;
    uint8 constant private BET_PLAYER_PAIR = 16;

    uint8[3] private _playerCards;
    uint8[3] private _bankerCards;

    function currentRound() public view returns (uint64, bytes32, uint, uint, uint8, uint8[], uint8[]) {
        return (_roundId, _seedHash, _roundStartTime, _roundEndTime, _result,
            cardArray(_playerCards), cardArray(_bankerCards));
    }

    function makeResult(uint seed) internal {
        uint8 roundResult = 0;
        (uint8 playerPoint, uint8 bankerPoint) = drawCards(seed);
        if (bankerPoint > playerPoint) {
            roundResult = BET_BANKER_WIN;
        } else if (playerPoint > bankerPoint) {
            roundResult = BET_PLAYER_WIN;
        } else {
            roundResult = BET_TIE;
        }

        if (_bankerCards[0] % 13 == _bankerCards[1] % 13) {
            roundResult |= BET_BANKER_PAIR;
        }
        if (_playerCards[0] % 13 == _playerCards[1] % 13) {
            roundResult |= BET_PLAYER_PAIR;
        }
        _result = roundResult;
    }

    function getPayout(Bet storage bet) internal returns (uint) {
        uint8 betType = bet.betType;
        if (betType & _result != 0) {
            if (betType == BET_BANKER_WIN) {
                return SafeMath.div(SafeMath.mul(bet.amount, 195), 100);
            } else if (betType == BET_PLAYER_WIN) {
                return SafeMath.mul(bet.amount, 2);
            } else if (betType == BET_TIE) {
                return SafeMath.mul(bet.amount, 9);
            } else if (betType == BET_BANKER_PAIR || betType == BET_PLAYER_PAIR) {
                return SafeMath.mul(bet.amount, 12);
            }
        }
        return 0;
    }

    function drawCards(uint seed) private returns (uint8, uint8) {
        uint8 playerPoint = 0;
        uint8 bankPoint = 0;
        uint8 cardDrawn = 0;
        uint8 drawnValue = 0;

        (seed, cardDrawn, drawnValue, playerPoint) = drawCard(playerPoint, seed);
        _playerCards[0] = cardDrawn;

        (seed, cardDrawn, drawnValue, playerPoint) = drawCard(playerPoint, seed);
        _playerCards[1] = cardDrawn;

        (seed, cardDrawn, drawnValue, bankPoint) = drawCard(bankPoint, seed);
        _bankerCards[0] = cardDrawn;

        (seed, cardDrawn, drawnValue, bankPoint) = drawCard(bankPoint, seed);
        _bankerCards[1] = cardDrawn;

        _playerCards[2] = 255;
        _bankerCards[2] = 255;

        if (bankPoint < 8 && playerPoint < 8) {
            bool bankerThirdCard = false;
            if (playerPoint < 6) {
                (seed, cardDrawn, drawnValue, playerPoint) = drawCard(playerPoint, seed);
                _playerCards[2] = cardDrawn;

                bankerThirdCard = bankerDrawThirdCard(bankPoint, drawnValue);
            } else {
                bankerThirdCard = bankPoint < 6;
            }

            if (bankerThirdCard) {
                (seed, cardDrawn, drawnValue, bankPoint) = drawCard(bankPoint, seed);
                _bankerCards[2] = cardDrawn;
            }
        }
        return (playerPoint, bankPoint);
    }

    function bankerDrawThirdCard(uint8 bankerPoint, uint8 playerThirdCard) private pure returns (bool) {
        if (bankerPoint <= 2) {
            return true;
        } else if (bankerPoint == 3) {
            return playerThirdCard != 8;
        } else if (bankerPoint == 4) {
            return playerThirdCard >= 2 && playerThirdCard <= 7;
        } else if (bankerPoint == 5) {
            return playerThirdCard >= 4 && playerThirdCard <= 7;
        } else if (playerThirdCard == 6) {
            return playerThirdCard == 6 || playerThirdCard == 7;
        }
        return false;
    }

    function drawCard(uint8 point, uint seed) private pure returns (uint, uint8, uint8, uint8) {
        uint8 card = uint8(seed % CARD_COUNT);
        seed = seed / CARD_COUNT;
        uint8 cardPoint = (card % 13) + 1;
        if (cardPoint >= 10) {
            cardPoint = 0;
        }
        point = (point + cardPoint) % 10;
        return (seed, card, cardPoint, point);
    }

    function cardArray(uint8[3] storage cards) private view returns (uint8[]) {
        uint8 thirdCard = cards[2];
        uint8[] memory result = new uint8[](thirdCard == 255 ? 2 : 3);
        result[0] = cards[0];
        result[1] = cards[1];
        if (thirdCard != 255) {
            result[2] = thirdCard;
        }
        return result;
    }
}

