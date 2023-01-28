// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract BookLibrary is Ownable {
    // bookId -> user address -> bool. List of currently borrowed books.
    // booksBorrowed[bookId][address] returns if the book is borrowed by that user.
    mapping (uint => mapping (address => bool)) booksBorrowed;

    // bookId -> int. Number of copies available to borrow for each book.
    mapping (uint => uint) stockAvailable; 

    Book[] public books;

    // bookId -> list of users who previously borrowed it
    mapping (uint => address[]) borrowHistory;

    struct Book {
        string name;
        bool inLibrary;
    }

    event BookAdded(uint id);

    event StockUpdated(uint bookId, uint previousCopies, uint newCopies);
    
    event BookBorrowed(uint id, address borrower, uint remaining);
    
    event BookReturned(uint id, address borrower, uint remaining);
    
    function borrowBook(uint _bookId) external {
        address borrower = msg.sender;
        require(!booksBorrowed[_bookId][borrower]); // checks the user has not already borrowed the same book
        require(stockAvailable[_bookId] > 0); // checks there are copies available

        // can borrow
        booksBorrowed[_bookId][borrower] = true;
        borrowHistory[_bookId].push(borrower);

        emit BookBorrowed(_bookId, borrower, stockAvailable[_bookId]);
    }

    function returnBook(uint _bookId) external {
        require(booksBorrowed[_bookId][msg.sender]);

        // can return
        booksBorrowed[_bookId][msg.sender] = false;
        
        emit BookReturned(_bookId, msg.sender, stockAvailable[_bookId]);
    }

    function getAvailableBooks() external view returns(Book[] memory) {
        uint totalAvailableBooks = 0;
        for (uint i = 0; i < books.length; i++) {
            if (stockAvailable[i] > 0) {
                totalAvailableBooks++;
            }
        }

        Book[] memory result = new Book[](totalAvailableBooks);
        for (uint i = 0; i < books.length; i++) {
            if (stockAvailable[i] > 0) {
                result[i] = books[i];
            }
        }

        return result;
    }

    function getBorrowerHistory(uint _bookId) external view returns(address[] memory) {
        return borrowHistory[_bookId];
    }

    function addBook(string memory _name, uint _copies) external onlyOwner {
        books.push(Book(_name, true));
        uint bookId = books.length - 1;

        emit BookAdded(bookId);

        setBookCopies(bookId, _copies);
    }

    function setBookCopies(uint _bookId, uint _copies) public onlyOwner {
        require(books[_bookId].inLibrary);
        require(_copies > 0);

        uint previousCopies = stockAvailable[_bookId];
        stockAvailable[_bookId] = _copies;

        emit StockUpdated(_bookId, previousCopies, _copies);
    }
}