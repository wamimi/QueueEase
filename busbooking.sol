// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BusBooking {
    address public owner;
    uint256 public seatPrice;
    uint256 public totalSeats;
    uint256 public seatsAvailable;
    mapping(address => uint256) public seatBookings;
    mapping(uint256 => address) public seatAssignments;
    mapping(uint256 => bool) public seatAvailability;
    mapping(address => uint256[]) public waitlist;

    event SeatBooked(address indexed passenger, uint256 seatNumber);
    event SeatCanceled(address indexed passenger, uint256 seatNumber);
    event SeatUpgraded(address indexed passenger, uint256 oldSeat, uint256 newSeat);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    constructor(uint256 _totalSeats, uint256 _seatPrice) {
        owner = msg.sender;
        totalSeats = _totalSeats;
        seatsAvailable = _totalSeats;
        seatPrice = _seatPrice;
        for (uint256 i = 1; i <= totalSeats; i++) {
            seatAvailability[i] = true;
        }
    }

    function bookSeat(uint256 _seatNumber) external payable {
        require(_seatNumber > 0 && _seatNumber <= totalSeats, "Invalid seat number");
        require(seatAvailability[_seatNumber], "Seat not available");
        require(msg.value >= seatPrice, "Insufficient payment");
        require(seatBookings[msg.sender] == 0, "You have already booked a seat");

        seatBookings[msg.sender] = _seatNumber;
        seatAssignments[_seatNumber] = msg.sender;
        seatsAvailable--;
        seatAvailability[_seatNumber] = false;

        emit SeatBooked(msg.sender, _seatNumber);
    }

    function cancelBooking() external {
        uint256 seatNumber = seatBookings[msg.sender];
        require(seatNumber != 0, "No seat booked");

        delete seatAssignments[seatNumber];
        delete seatBookings[msg.sender];
        seatsAvailable++;
        seatAvailability[seatNumber] = true;

        payable(msg.sender).transfer(seatPrice); // Refund the payment

        emit SeatCanceled(msg.sender, seatNumber);
    }

    function upgradeSeat(uint256 _newSeatNumber) external payable {
        uint256 oldSeatNumber = seatBookings[msg.sender];
        require(oldSeatNumber != 0, "No seat booked");
        require(_newSeatNumber > 0 && _newSeatNumber <= totalSeats, "Invalid seat number");
        require(seatAvailability[_newSeatNumber], "Seat not available");
        require(msg.value >= seatPrice, "Insufficient payment");

        delete seatAssignments[oldSeatNumber];
        seatBookings[msg.sender] = _newSeatNumber;
        seatAssignments[_newSeatNumber] = msg.sender;
        seatAvailability[_newSeatNumber] = false;
        seatAvailability[oldSeatNumber] = true;

        emit SeatUpgraded(msg.sender, oldSeatNumber, _newSeatNumber);
    }

    function addToWaitlist(uint256 _seatNumber) external {
        require(seatsAvailable == 0, "Seats available, no need to join waitlist");
        require(_seatNumber > 0 && _seatNumber <= totalSeats, "Invalid seat number");

        waitlist[msg.sender].push(_seatNumber);
    }

    function removeFromWaitlist(uint256 _seatNumber) external {
        uint256[] storage passengerWaitlist = waitlist[msg.sender];
        require(passengerWaitlist.length > 0, "No seats in waitlist");

        for (uint256 i = 0; i < passengerWaitlist.length; i++) {
            if (passengerWaitlist[i] == _seatNumber) {
                passengerWaitlist[i] = passengerWaitlist[passengerWaitlist.length - 1];
                passengerWaitlist.pop();
                break;
            }
        }
    }

    function getWaitlist(address _passenger) external view returns (uint256[] memory) {
        return waitlist[_passenger];
    }

    function withdrawFunds() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
