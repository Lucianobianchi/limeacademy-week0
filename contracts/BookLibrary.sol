// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract BookLibrary is Ownable {
    // bookId -> user address -> bool. List of currently borrowed books.
    // booksBorrowed[bookId][address] returns if the book is borrowed by that user.
    mapping (uint => mapping (address => bool)) booksBorrowed;

    // bookId -> int. Number of copies available to borrow for each book.
    mapping (uint => uint) public stockAvailable; 

    Book[] public books;

    // bookId -> list of users who previously borrowed it
    mapping (uint => address[]) public borrowHistory;

    struct Book {
        string name;
        bool inLibrary;
    }

    event BookAdded(uint id);

    event StockUpdated(uint bookId, uint previousCopies, uint newCopies);
    
    event BookBorrowed(uint id, address borrower, uint remaining);
    
    event BookReturned(uint id, address borrower, uint remaining);
    
    /**
     * @dev Borrow book from library
     * @param _bookId id of the book to borrowed
     */
    function borrowBook(uint _bookId) external {
        address borrower = msg.sender;
        require(!booksBorrowed[_bookId][borrower], "User already borrowed this book"); 
        require(stockAvailable[_bookId] > 0, "No book copies available"); 

        // can borrow
        booksBorrowed[_bookId][borrower] = true;
        borrowHistory[_bookId].push(borrower);
        stockAvailable[_bookId]--;

        emit BookBorrowed(_bookId, borrower, stockAvailable[_bookId]);
    }

    /**
     * @dev Return book to library
     * @param _bookId id of the book to return. Book has to be previously borrowed before returning.
     */
    function returnBook(uint _bookId) external {
        require(booksBorrowed[_bookId][msg.sender], "User has not borrowed this book");

        // can return
        booksBorrowed[_bookId][msg.sender] = false;
        stockAvailable[_bookId]++;
        
        emit BookReturned(_bookId, msg.sender, stockAvailable[_bookId]);
    }

    struct BookAvailability {
        uint bookId;
        uint copies;
    }

    /**
     * @dev Gets a list of all books with copies available for borrowing.
     * @return availability_ array of BookAvailability, only contains books with one or more copies.
     */
    function getAvailableBooks() external view returns(BookAvailability[] memory availability_) {
        uint totalAvailableBooks = 0;
        for (uint i = 0; i < books.length; i++) {
            if (stockAvailable[i] > 0) {
                totalAvailableBooks++;
            }
        }

        BookAvailability[] memory result = new BookAvailability[](totalAvailableBooks);
        uint j = 0;
        for (uint i = 0; i < books.length; i++) {
            if (stockAvailable[i] > 0) {
                result[j] = BookAvailability(i, stockAvailable[i]);
                j++;
            }
        }

        return result;
    }

    /**
     * @dev Add a book to the library.
     * @param _name the book name
     * @param _copies the initial copies of the book
     */
    function addBook(string memory _name, uint _copies) external onlyOwner {
        books.push(Book(_name, true));
        uint bookId = books.length - 1;

        emit BookAdded(bookId);

        setAvailableBookCopies(bookId, _copies);
    }

    /**
     * @dev Returns a list of all the borrowers for a book.
     * @param _bookId id of the book
     */
    function getBorrowHistory(uint _bookId) external view returns(address[] memory) {
        return borrowHistory[_bookId];
    }

    /**
     * @dev Sets the amount of available copies for an existing book in the library.
     * @param _bookId id of the book
     * @param _copies new amount of copies. Will replace the existing number of available copies. 
     */
    function setAvailableBookCopies(uint _bookId, uint _copies) public onlyOwner {
        require(books[_bookId].inLibrary, "Book not in library");

        uint previousCopies = stockAvailable[_bookId];
        stockAvailable[_bookId] = _copies;

        emit StockUpdated(_bookId, previousCopies, _copies);
    }
}