//
//  CalendarViewController.swift
//  LyonsDen
//
//  The CalendarViewContrller will be used for displaying the calendar as well as events associated with selected dates.
//
//  Created by Inal Gotov on 2016-06-30.
//  Copyright © 2016 William Lyon Mackenize CI. All rights reserved.
//

import UIKit
import SystemConfiguration

// TODO: FIX LOCATION LABEL GETTING OUT OF ITS BOUNDS

class CalendarViewController: UIViewController, CalendarViewDataSource, CalendarViewDelegate {
    // The Calendar View
    // The size doesnt matter, it will resize it self later.
    var calendarView:CalendarView = CalendarView(frame: CGRect.zero)
    // The loading wheel that is displayed
    @IBOutlet var loadingWheel: UIActivityIndicatorView!
    // The menu button on the Navigation Bar
    @IBOutlet weak var menuButton: UIBarButtonItem!
    // Label when loading data
    @IBOutlet weak var loadingLabel: UILabel!
    
    // The scroll view, containing each event
    var scrollView:UIScrollView?
    // An array of events for the currently selected day
    var currentEvents:[EventView?] = []
    // The last selected day
    var lastSelectedDate:Date?
    // The label representing a strigified version of the currently selected date
    let dateLabel = UILabel()
    
    var labelAnimator: Timer?
    var labelCounter = 4
    var currentLabelHorizontal:CGFloat = 0
    
    // Called when the segue initiating button is pressed
    override func viewDidLoad() {
        // Super call
        super.viewDidLoad()
        // Start the animation of the loading wheel
        loadingWheel.startAnimating()
        labelAnimator = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(changeLoadingLabel), userInfo: nil, repeats: true)
//        labelAnimator = Timer (timeInterval: 1, target: self, selector: #selector(changeLoadingLabel), userInfo: nil, repeats: true)
        
        loadingWheel.hidesWhenStopped = true
        
        // Make sidemenu swipeable
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()                                     // Set Button Target class
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))              // Set Button Target method
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())  // Create a gesture recognizer in the ViewController
        }
        // Set the DataSource and Delegate of the calendar
        calendarView.dataSource = self
        calendarView.delegate = self
        calendarView.backgroundColor = colorBackground
        // Create a place holder for the calendar's height
        let calendarHeight = self.view.frame.size.width + 50.0
        
        // Setup the scrollView
        scrollView = UIScrollView(frame: CGRect(x: 0, y: calendarHeight + 2, width: self.view.frame.width, height: self.view.frame.height - calendarHeight))
        scrollView!.backgroundColor = colorBackground                           // Set the scrollView's background color
        dateLabel.frame = CGRect(x: 8, y: 8, width: scrollView!.frame.width - 16, height: 21)    // Resize and position the dateLabel
        dateLabel.textColor = colorEventViewBackground.withAlphaComponent(0.85)                                       // Change the text color of the dateLabel
        dateLabel.text = ""                                                     // Set a place holder for the text of the dateLabel
        dateLabel.textAlignment = NSTextAlignment.center                        // Center the dateLabel's text on screen
        scrollView!.addSubview(dateLabel)                                       // Add the dateLabel to the scrollView
        
        // Add the calendar and scrollView to the main view and hide them until events are loaded
        self.view.addSubview(calendarView)
        self.view.addSubview(scrollView!)
        calendarView.isHidden = true
        scrollView?.isHidden = true
        
        // Initiate the loading of events from the web.
        self.loadEventsIntoCalendar()
    }
    
    func resetDate () {
        print ("I've Been Summoned!")
        self.calendarView.setDisplayDate(Date(), animated: true)
    }
    
    func changeLoadingLabel () {
        var currentText = loadingLabel.text
//        print (self.loadingLabel.frame.origin.x)
        
        if labelCounter < 3 {
            currentLabelHorizontal = loadingLabel.frame.origin.x
            labelCounter += 1
            currentText? += "."
            // Add a dot to it
        } else {    // "Just Loading", "Making sure you're on time", "Loading, just for you", "Unloading"
            labelCounter = 0
            // For this we will probably need a file containing them
            let labelBank = ["Just Loading", "Making sure you're on time", "Loading, just for you", "UnLoading", "I, am your loader!"]
            // Change the label
            let index:Int = Int(arc4random_uniform(UInt32(labelBank.count)))
            currentText = labelBank[index]
        }
        
        DispatchQueue.main.async {
            self.loadingLabel.text? = currentText!
        }
    }
    
    // Called before apearing
    override func viewDidLayoutSubviews() {
        // Super call
        super.viewDidLayoutSubviews()
        // Declare the width and height of the calendar
        let width = self.view.frame.size.width - 16.0 * 2
        let height = width + 20.0
        self.calendarView.frame = CGRect(x: 16.0, y: 60.0, width: width, height: height)    // Resize and position the calendar on screen


        // If there are any events in the current date, then resize the scrollView's contentSize accordingly
        if self.currentEvents.count > 0 {   // If an event exists
            var contentHeight:CGFloat = 37
//            self.scrollView!.contentSize.height = 37 + (self.currentEvents[0]!.frame.height + 16) * CGFloat(self.currentEvents.count)
            self.scrollView?.contentSize.height = 37
            for view in self.currentEvents {
                self.scrollView?.contentSize.height += (view?.frame.height)! + 8
                contentHeight += (view?.frame.height)! + 8
            }
        } else {                            // If an event does not exist
            self.scrollView!.contentSize.height = self.scrollView!.frame.height
        }

        // Loading Label Location Fix (...)
        if !self.loadingLabel.isHidden && self.labelCounter < 4 && self.labelCounter != 0 {
            self.loadingLabel.frame.origin.x = currentLabelHorizontal
        }
    }
    
// MARK: DEBUGGING
    // Called whenever the events have been loaded
    func eventsDidLoad(loadSuccess:Bool) {
        DispatchQueue.main.async {
            self.calendarView.reloadData()
            
            self.calendarView.alpha = 0
            self.scrollView?.alpha = 0
            // Unhide the calendar and scrollView
            self.calendarView.isHidden = false
            self.scrollView?.isHidden = false
            
            UIView.animate(withDuration: 0.3, animations: {
                self.calendarView.alpha = 1
                self.scrollView?.alpha = 1
                self.loadingWheel.alpha = 0
                self.loadingLabel.alpha = 0
            })
            
//            print ("Events finished loading")
            // Stop the loading wheel
            self.loadingWheel.stopAnimating()
            self.labelAnimator?.invalidate()
            self.labelAnimator = nil
            self.loadingLabel.isHidden = true
//            print ("Loading Label Hidden")
            
            if !loadSuccess {
                var message = "Calendar Not Available"
                message += (self.calendarView.events != nil) ? "\nShowing Last Updated\nCalendar" : ""
                
                let toast = ToastView(inView: self.view, withText: message, andDuration: 2)
                self.view.addSubview(toast)
                toast.initiate()
            }
            
            self.resetDate()                          // Set the current displayed date on the calendar, to the current date
            self.calendarView.reloadData()
        }
    }
    
    func addEventView (view:EventView) {
        self.currentEvents.append(view)
        if currentEvents.count > 1 {
            let newPosition = (currentEvents[currentEvents.count-2]?.frame.origin.y)! + (currentEvents[currentEvents.count-2]?.frame.height)! + 8
            currentEvents[currentEvents.count - 1]?.frame.origin.y = newPosition
        }
        
        self.scrollView?.addSubview(view)
    }
    
// MARK: EVENTS
    
    /* This function handles the process of downloading a calendar file from the web and parsing it, to add it to the app's calendar.
    The Process: Check Internet Connection
    If available then download new calendar and display
    If not available then check if cache exists
        If a cache exists then display that and notify user about calendar's state
        If no cache exists then display empty calendar and notify user about calendar's state
    */
    func loadEventsIntoCalendar() {
        // The link from which the calendar is downloaded
        let url = URL (string: "https://calendar.google.com/calendar/ical/wlmacci%40gmail.com/public/basic.ics")!
        
        
        // The process of downloading and parsing the calendar
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            // The following is simply a declaration and will not execute without the line 'task.resume()'
            if let URLContent = data {  // If Data has been loaded
                // If you got to this point then you've downloaded the calendar so...
                // Calendar File parsing starts here!!!
                // The string that holds the contents of the calendar's events
                let webContent:NSString = NSString(data: URLContent, encoding: String.Encoding.utf8.rawValue)!
                
                // Pass the recorded events to the calendar
                self.calendarView.events = self.parse(webContent, inCalendar: self.calendarView.calendar)
                
                // Update the cached calendar
                UserDefaults.standard.setValue(webContent, forKey: keyCalendarEventBank)
                
                // Notify the ViewController that the events have been loaded
                self.eventsDidLoad(loadSuccess: true)
            }
        })
        
        // Response can be used to further error trap or check what the error is
        // 'available' will be false if the connection is not perfect (doesn't mean its not there)
        checkInternet { (available, response) in
            if available {  // Then proceed
                // Initiate the calendar loading process
                task.resume()
            } else {    // You can try error handling, or just not
                let content = UserDefaults.standard.string(forKey: keyCalendarEventBank) as NSString?
                if content != nil {
                    self.calendarView.events = self.parse(content!, inCalendar: self.calendarView.calendar)
                }
                
                self.eventsDidLoad(loadSuccess: false)
            }
        }
    }
    
    // Calendar Parser for this VC
    func parse(_ webContent:NSString, inCalendar calendar:Calendar) -> [Event] {
        var dayDictionary:[String: Int]? = (UserDefaults.standard.dictionary(forKey: keyDayDictionary) == nil) ? [String: Int]() : nil
        
        // An array of flags used for locating the event fields
        // [h][0] - The flag that marks the begining of a field, [h][1] - The flag that marks the end of a field
        let searchTitles:[[String]] = [["SUMMARY:", "TRANSP:"], ["DESCRIPTION:", "LAST-MODIFIED:"], ["DTSTART", "DTEND"], ["DTEND", "DTSTAMP"], ["LOCATION:", "SEQUENCE:"]]
        // The set that will contain the events themselves
        var eventBank:Set<Event> = Set<Event>()
        // An array of operation for configuring the last added event, operations are in the same order as searchTitles.
        // The operations automatically modify the last item in the 'events' array.
        // The actual contents of this array are calculated at the time of access and will be different as defined in the if statement
        // Read the whole chapter on 'Functions' in the txtbook, there's some interesting stuff there, it'll all make sense
        
        var curEvent = Event(calendar: calendar)
        
        var eventOperations:[(NSString) -> Void] {
            return [curEvent.setTitle, curEvent.setDescription, curEvent.setStartDate, curEvent.setEndDate, curEvent.setLocation]
        }
        
        // The range of "webContent's" content that is to be scanned
        // Must be decreased after each event is scanned
        var range:NSRange = NSMakeRange(0, webContent.length - 1)
        // Inside function that will be used to determine the 'difference' range between the begining and end flag ranges.
        let findDifference:(NSRange, NSRange) -> NSRange = {(first:NSRange, second:NSRange) -> NSRange in
            let location = first.location + first.length, length = second.location - location   // Determine the start position and length of our new range
            return NSMakeRange(location, length)                                                // Create and return the new range
        }
        // Inside function that will be used to move the searching range to the next event
        // Returns an NSNotFound range (NSNotFound, 0) if there are not more events
        let updateRange:(NSRange) -> NSRange = {(oldRange:NSRange) -> NSRange in
            let beginingDeclaration = webContent.range(of: "BEGIN:VEVENT", options: NSString.CompareOptions.literal, range: oldRange)
            // If the "BEGIN:VEVENT" was not found in webContent (no more events)
            if NSEqualRanges(beginingDeclaration, NSMakeRange(NSNotFound, 0)) {
                return beginingDeclaration  // Return an 'NSNotFound' range (Named it myself;)
            }
            // Calculate the index of the last character of 'beginingDeclaration' flag
            let endOfBeginingDeclaration = beginingDeclaration.location + beginingDeclaration.length
            // Calculate the length of the new range
            let length = oldRange.length - endOfBeginingDeclaration + oldRange.location
            // Calculate the starting location of the new range
            let location = endOfBeginingDeclaration
            // Create and return the new range
            return NSMakeRange(location, length)
        }
        
        // A holder for the begining and end flags for each event field
        var fieldBoundaries:[NSRange]
        // The actual parsing of each event
        repeat {
            range = updateRange(range)  // Move our searching range to the next event
            if NSEqualRanges(range, NSMakeRange(NSNotFound, 0)) {   // If there are no more events in the searching range
                break;                                              // Then no more shall be added (break from the loop)
            }
            
            // Record each field into our event database
            for h in 0...searchTitles.count-1 {
                fieldBoundaries = [NSRange]()   // Clear the fieldBoundaries for the new search
                fieldBoundaries.append(webContent.range(of: searchTitles[h][0], options: NSString.CompareOptions.literal, range: range))   // Find the begining flag
                fieldBoundaries.append(webContent.range(of: searchTitles[h][1], options: NSString.CompareOptions.literal, range: range))   // Find the ending flag
                var tempHold:String = webContent.substring(with: findDifference(fieldBoundaries[0], fieldBoundaries[1]))                         // Create a new string from whatever is in between the two flags. This will be the current field of the event
                tempHold = tempHold.trimmingCharacters(in: CharacterSet.newlines)                                           // Remove all /r /n and other 'new line' characters from the event field
                tempHold = tempHold.replacingOccurrences(of: "\u{005C}", with: "", options: .literal, range: nil)           // Replace all backslashes from the event field
                eventOperations[h](tempHold as NSString)                                                                                                        // Add the event field to the current event being recorded
            }
            
            if curEvent.title.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "day 1" || curEvent.title.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) == "day 2" {
                dayDictionary?[((curEvent.startDate?.description)! as NSString).substring(to: 10)] = Int ((curEvent.title as NSString).substring(from: curEvent.title.characters.count - 1))
            } else {
                eventBank.insert(curEvent)
            }
            curEvent = Event(calendar: calendar)
        } while (true)
        
        if dayDictionary != nil {
            UserDefaults.standard.set(dayDictionary!, forKey: keyDayDictionary)
        }
        
        return Array(eventBank)
    }
    

// MARK: CALENDAR DATASOURCE IMPLEMENTATION
    
    // Set the start date that can be viewed with the calendar
    func startDate() -> Date? {
        // This will be changed
        
        // Declare a dateComponents to hold the date values
        var dateComponents = DateComponents()
        
        /////////////////////////////////////////////////////////////////
        // This is what you need to change, everything else works fine //
        // Set how far back the calendar can be viewed                 //
        /////////////////////////////////////////////////////////////////
        dateComponents.month = -5
        // rewind the clock 4 hours so that it is in our time zone. TEMPORARY FIX
        dateComponents.hour = -4
        
        // Declare today's date
        let today = Date()
        // Declare the range of the between the start date and today
        let startDate = (self.calendarView.calendar as NSCalendar).date(byAdding: dateComponents, to: today, options: NSCalendar.Options())!
        // Return the start date
        return startDate
    }
    
    // Set the end date that can be viewed with the calendar
    func endDate() -> Date? {
        // This will be changed
        
        // Declare a dateComponents to hold the date values
        var dateComponents = DateComponents()
        
        /////////////////////////////////////////////////////////////////
        // This is what you need to change, everything else works fine //
        // Set how far the calendar can be viewed                      //
        /////////////////////////////////////////////////////////////////
        dateComponents.year = 1;
        
        // Declare today's date
        let today = Date()
        // Declare the range of the between the end date and today
        let oneYearsFromNow = (self.calendarView.calendar as NSCalendar).date(byAdding: dateComponents, to: today, options: NSCalendar.Options())
        // Return the end date
        return oneYearsFromNow
    }
    
// MARK: CALENDAR DELEGATE IMPLEMENTATION
    
    // Called before selecting a date (I think). Required to be implemented
    func calendar(_ calendar: CalendarView, canSelectDate date: Date) -> Bool { return true }
    
    // Called when a month is scrolled in the calendar. Required to be implemented
    func calendar(_ calendar: CalendarView, didScrollToMonth date: Date) {}
    
    // Called when a date is deselected. Required to be implemented
    func calendar(_ calendar: CalendarView, didDeselectDate date: Date) {}
    
    // Called when a date is selected. Required to be implemented
    func calendar(_ calendar: CalendarView, didSelectDate date: Date, withEvents events: [Event]) {
        if let lastDate = lastSelectedDate {
            if date == lastDate {
                return
            }
            self.calendarView.deselectDate(lastDate)
        }
        lastSelectedDate = date
        
        DispatchQueue.main.async {
            self.currentEvents.removeAll()
            if self.scrollView!.subviews.count > 0 {
                for subview in self.scrollView!.subviews {
                    if subview != self.dateLabel {
                        subview.removeFromSuperview()
                    }
                }
            }
            if (events.count > 0) {
                for h in 0...events.count - 1 {
                    var dateTime = (events[h].startDate!.description as NSString).substring(to: 16) as NSString
                    dateTime = dateTime.substring(from: 11) as NSString
                    dateTime = (dateTime == "00:00") ? "" : dateTime
                    let params:[String?] = [events[h].title,
                                            events[h].description,
                                            dateTime as String,
                                            events[h].location]
                    self.addEventView(view: EventView(withFrame: CGRect(x: 8, y: 37, width: self.scrollView!.frame.width - 16, height: 316), params: params))
                }
            }
            let key = (date.description as NSString).substring(to: 10)
            let dayOfDate = (UserDefaults.standard.dictionary(forKey: keyDayDictionary))?[key] as! Int?
            self.dateLabel.text = NSString(string: date.description).substring(to: 10)
            if dayOfDate != nil { self.dateLabel.text = self.dateLabel.text! + " Day \(dayOfDate!)"}
        }
    }
}
