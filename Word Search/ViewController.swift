//
//  ViewController.swift
//  Word Search
//
//  Created by Brian Kim on 2020-08-26.
//  Copyright © 2020 Brian Kim. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    // Cell struct for storing each cell of the game board.
    struct Cell {
        var row: Int
        var col: Int
    }
    
    // Outlet Initializations
    @IBOutlet weak var innerView: UIView!
    @IBOutlet var pausedView: UIView!
    @IBOutlet var gameEndedView: UIView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var didWinLabel: UILabel!
    @IBOutlet weak var totalFoundLabel: UILabel!
    @IBOutlet weak var resetButton: UIBarButtonItem!
    @IBOutlet weak var pauseButton: UIBarButtonItem!
    @IBOutlet weak var replayButton: UIButton!
    
    // Object Initializations
    var gameBoardArray = [[String]]()
    var gameBoard = [String]()
    var answerCell = [String:[Cell]]()
    var wordArray = ["SWIFT", "KOTLIN", "OBJECTIVEC", "VARIABLE", "JAVA", "MOBILE"]
    var alphabetArray = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    var totalFound = 0
    var timeLeft = 90
    var timer = Timer()
    var gamePaused = false
    var effect: UIVisualEffect!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Start timer which runs countDown function for each interval
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(countDown), userInfo: nil, repeats: true)
        
        // Set up gameboard
        initializeBoard()
        
        // Register cells and set delegate & dataSource
        collectionView.register(UINib(nibName: "ItemCell", bundle: nil), forCellWithReuseIdentifier: "Cell")
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Initial view settings
        effect = visualEffectView.effect
        visualEffectView.effect = nil
        visualEffectView.alpha = 1
        
        pausedView.layer.cornerRadius = 5
        innerView.layer.cornerRadius = 10
        
        // Show the time on time label
        let minutes = timeLeft / 60
        let seconds = timeLeft % 60
        timeLabel.text = String(format: "%02i:%02i", minutes, seconds)
    }
    
    // This function decrements time variable when run and outputs it. If time has run out, disable timer and call gameEnded()
    @objc func countDown() {
        timeLeft -= 1
        
        if timeLeft == 0 {
            timer.invalidate()
            gameEnded()
        }
        
        let minutes = timeLeft / 60
        let seconds = timeLeft % 60
        
        timeLabel.text = String(format: "%02i:%02i", minutes, seconds)
    }
    
    // This IBAction resets current game, after checking whether game is paused or has ended
    @IBAction func replayGame(_ sender: Any) {
        if !gamePaused {
            gameEndedView.removeFromSuperview()
            resetButton.isEnabled = true
        } else {
            keepPlayingButton(self)
        }
        resetGame(self)
    }
    
    // This IBAction resets current game
    @IBAction func resetGame(_ sender: Any) {
        timer.invalidate()
        
        // Remove the labels with strikethorugh text with normal next
        for (index, word) in wordArray.enumerated() {
            if let label = self.view.viewWithTag(index+1) as? UILabel {
                let attributedString = NSMutableAttributedString(string: word)
                attributedString.removeAttribute(NSAttributedString.Key.strikethroughStyle, range: NSMakeRange(0, attributedString.length))
                label.attributedText = attributedString
            }
        }
        
        // Reset the background color of the collectionView cells with original colour
        for row in 0...collectionView.numberOfItems(inSection: 0)-1 {
            let cellIndex = IndexPath(row: row, section: 0)
            if let cell = collectionView.cellForItem(at: cellIndex) {
                cell.isUserInteractionEnabled = true
                cell.backgroundColor = UIColor(red: 120/255, green: 224/255, blue: 143/255, alpha: 1.0)
            }
        }
        
        // Initialize the game board array
        initializeBoard()

        pauseButton.isEnabled = true
        collectionView.isUserInteractionEnabled = true
        collectionView.reloadData()
        
        gamePaused = false
        totalFound = 0
        totalFoundLabel.text = String(totalFound)
        timeLeft = 90
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(countDown), userInfo: nil, repeats: true)
        
        let minutes = timeLeft / 60
        let seconds = timeLeft % 60
        timeLabel.text = String(format: "%02i:%02i", minutes, seconds)
    }
    
    // This IBAction pauses the current game by disabling timer and animate-in a new pausedView View
    @IBAction func pauseGame(_ sender: Any) {
        gamePaused = true
        timer.invalidate()
        
        self.view.addSubview(pausedView)
        pausedView.center = self.view.center
        
        pausedView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        pausedView.alpha = 0
        visualEffectView.isHidden = false
        
        UIView.animate(withDuration: 0.4) {
            self.visualEffectView.effect = self.effect
            self.pausedView.alpha = 1
            self.pausedView.transform = CGAffineTransform.identity
        }
    }
    
    // This IBAction will animate-out the removing of the pausedView subView from the current view and resume the timer
    @IBAction func keepPlayingButton(_ sender: Any) {
        UIView.animate(withDuration: 0.3, animations: {
            self.pausedView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            self.pausedView.alpha = 0
            
            self.visualEffectView.effect = nil
        }) { (success) in
            self.pausedView.removeFromSuperview()
        }
        
        visualEffectView.isHidden = true
        gamePaused = false
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(countDown), userInfo: nil, repeats: true)
    }
    
    // Initialize the 2D and 1D representation the game board/collection view grid
    func initializeBoard() {
        // Initialize game board with placeholder #
        gameBoardArray = [[String]]()
        answerCell = [String:[Cell]]()
        
        // Insert placeholder character to each cell in the game board
        for _ in 0...9 {
            let tempArray: [String] = ["#", "#", "#", "#", "#", "#", "#", "#", "#", "#"]
            gameBoardArray.append(tempArray)
        }
        
        // Randomly check for space for each words and if space available, then place the word
        for n in 0...wordArray.count-1 {
            var spaceFound = false
            
            while !spaceFound {
                let row = Int.random(in: 0...9)
                let col = Int.random(in: 0...9)
                let direction = checkForSpace(wordIndex: n, row: row, col: col)
                
                if direction == "right" || direction == "down" || direction == "left" || direction == "up" || direction == "diagonal" {
                    placeWord(wordIndex: n, direction: direction, row: row, col: col)
                    spaceFound = true
                    
                    print(direction)
                }
            }
        }
        
        // When all the words are randomly placed out on the game board grid, fill the rest of the cell with random alphabets
        for (i, row) in gameBoardArray.enumerated() {
            for (j, char) in row.enumerated() {
                if char == "#" {
                    if let randChar = alphabetArray.randomElement() {
                        gameBoardArray[i][j] = randChar
                    }
                }
            }
        }
        
        // Create a flat, 1D array representation of the 2D game board for the collection view layout
        gameBoard = gameBoardArray.reduce([], +)
    }
    
    // This function checks if there is space for a word at wordIndex at specific row and col. Returns the direction of the available space.
    func checkForSpace(wordIndex: Int, row: Int, col: Int) -> String {
        // checks for space in 4 directions -> right down left up
        var result = "none"
        let word = wordArray[wordIndex]
        let directions = ["diagonal", "right", "down", "left", "up"]
        let direction = directions.randomElement()
        
        if ((row + word.count-1 <= 9) && (col + word.count-1 <= 9) && direction == "diagonal") {
            // Check diagonally
            var free = true
            for n in 0...word.count-1 {
                if gameBoardArray[row+n][col+n] != "#" {
                    free = false
                    break
                }
            }
            
            if free {
                result = "diagonal"
            }
        } else if  (col + word.count <= 10) && direction == "right" {
            // Check right
            var free = true
            for n in col...col+word.count-1 {
                if gameBoardArray[row][n] != "#" {
                    free = false
                    break
                }
            }
            
            if free {
                result = "right"
            }
        } else if (row + word.count <= 10) && direction == "down" {
            // Check down
            var free = true
            for n in row...row+word.count-1 {
                if gameBoardArray[n][col] != "#" {
                    free = false
                    break
                }
            }
            
            if free {
                result = "down"
            }
        } else if (col - word.count >= -1) && direction == "left" {
            // Check left
            var free = true
            for n in col-word.count+1...col {
                if gameBoardArray[row][n] != "#" {
                    free = false
                    break
                }
            }
            
            if free {
                result = "left"
            }
        } else if (row - word.count >= -1) && direction == "up" {
            // Check up
            var free = true
            for n in row-word.count+1...row {
                if gameBoardArray[n][col] != "#" {
                    free = false
                    break
                }
            }
            
            if free {
                result = "up"
            }
        }
        
        return result
    }
    
    // This function places word at wordIndex to a certain direction from a specific row, col coordinate in the game board
    func placeWord(wordIndex: Int, direction: String, row: Int, col: Int) {
        let word = wordArray[wordIndex]
        var cellArray = [Cell]()
        
        // Place each characters to the game board and append the cell to the answers cell array, which keeps track of all cells which is part of a word
        for (index, item) in word.enumerated() {
            let char = String(item)
            
            if direction == "right" {
                gameBoardArray[row][col+index] = char
                cellArray.append(Cell(row: row, col: col+index))
            } else if direction == "down" {
                gameBoardArray[row+index][col] = char
                cellArray.append(Cell(row: row+index, col: col))
            } else if direction == "left" {
                gameBoardArray[row][col-index] = char
                cellArray.append(Cell(row: row, col: col-index))
            } else if direction == "up" {
                gameBoardArray[row-index][col] = char
                cellArray.append(Cell(row: row-index, col: col))
            } else if direction == "diagonal" {
                gameBoardArray[row+index][col+index] = char
                cellArray.append(Cell(row: row+index, col: col+index))
            }
        }
        
        // Append to the answerCell dictionary with the new set of answers in cellArray
        answerCell[word] = cellArray
    }
    
    // This function checks if the given row, col coordinates is part of a word. Returns the word if it is, 'none' if not found
    func checkAnswer(row: Int, col: Int) -> String {
        var result = "none"
        
        for (word, cells) in answerCell {
            for cell in cells {
                if cell.row == row && cell.col == col {
                    result = word
                }
            }
        }
        
        return result
    }
    
    // This function is called when the timeLeft hits zero
    // Disable the user interaction for the game and animate-in the gameEndedView View which shows the user if he/she has won or lost
    // The gameEndedView has a button for replaying/retrying
    func gameEnded() {
        collectionView.isUserInteractionEnabled = false
        pauseButton.isEnabled = false
        resetButton.isEnabled = false
        
        self.view.addSubview(gameEndedView)
        gameEndedView.layer.cornerRadius = 10
        gameEndedView.center = CGPoint(x: self.view.center.x-500, y: self.view.center.y+105)
        
        if totalFound == wordArray.count {
            didWinLabel.text = "You've Won!"
            print(replayButton.title(for: .normal))
            replayButton.setTitle("Replay", for: .normal)
            
        } else {
            didWinLabel.text = "Time Out!"
            replayButton.setTitle("Retry", for: .normal)
        }
        
        UIView.animate(withDuration: 1) {
            self.gameEndedView.center = CGPoint(x: self.view.center.x, y: self.view.center.y+105)
        }
    }
    
    // Sets the number of items of collection to the gameBoard item count
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gameBoard.count
    }
    
    // Set up the cell with the resuasble cell 'Cell'
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ItemCell
        cell.setData(alphabet: gameBoard[indexPath.row])
        
        return cell
    }
    
    // This function is called when a collection View cell is tapped/selected
    // Get the 2D array row, col representation of the selected indexPath and checks if the selected cell is successfully a cell containing an alphabet for a word
    // If all words found, then end the game
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = indexPath.row / 10
        let col = indexPath.row % 10
        var tag = 0
        
        // Checks answer
        let wordFound = checkAnswer(row: row, col: col)
        if wordFound != "none" {
            for (index, word) in wordArray.enumerated() {
                if word == wordFound {
                    tag = index + 1
                    
                    if let cells = answerCell[word] {
                        for cell in cells {
                            let answerIndex = IndexPath(row: cell.row * 10 + cell.col, section: 0)
                            if let tempCell = collectionView.cellForItem(at: answerIndex) {
                                tempCell.backgroundColor = UIColor.systemPink
                                tempCell.isUserInteractionEnabled = false
                            }
                        }
                    }
                }
            }
            
            totalFound += 1
            totalFoundLabel.text = String(totalFound)
            
            // When found, strikeout the output label texts of each words
            let attributedString = NSMutableAttributedString(string: wordFound)
            attributedString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributedString.length))
            if let label = self.view.viewWithTag(tag) as? UILabel {
                label.attributedText = attributedString
            }
        }
        
        // If all words are successfully found, disable timer and end the game
        if totalFound == wordArray.count {
            timer.invalidate()
            gameEnded()
        }
    }
}
