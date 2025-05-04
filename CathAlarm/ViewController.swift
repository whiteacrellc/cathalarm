import UIKit
import UserNotifications
import os

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var intervalTextField: UITextField!
    
    var timer: Timer?
    var nextNotificationDate: Date?
    var notificationInterval: Double = 4.0 // Default: 4 hours
    
    private let logger = Logger(subsystem: "com.example.NotificationApp", category: "ViewController")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        intervalTextField.delegate = self
        intervalTextField.text = "\(notificationInterval)"
        intervalTextField.keyboardType = .numberPad
        intervalTextField.autocorrectionType = .no
        intervalTextField.textContentType = .none
        requestNotificationPermission()
        updateTimeLabel()
        
        
        // Add black border to buttons
        startButton.layer.borderColor = UIColor.black.cgColor
        startButton.layer.borderWidth = 2.0
        startButton.layer.cornerRadius = 8.0 // Optional: rounded corners
        
        cancelButton.layer.borderColor = UIColor.black.cgColor
        cancelButton.layer.borderWidth = 2.0
        cancelButton.layer.cornerRadius = 8.0 // Optional: rounded corners
        
        intervalTextField.layer.borderColor = UIColor.black.cgColor
        intervalTextField.layer.borderWidth = 2.0
        intervalTextField.layer.cornerRadius = 8.0 // Optional: rounded corners
    }
    
    // Handle Start Notifications button
    @IBAction func startButtonTapped(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.intervalTextField.resignFirstResponder()
            print("Keyboard dialog dismissed via startButtonTapped")
            self.logger.info("Keyboard dialog dismissed via startButtonTapped")
        }
        
        if let text = intervalTextField.text, let hours = Double(text), hours > 0 {
            notificationInterval = hours
        } else {
            // Show alert for invalid input
            let alert = UIAlertController(title: "Invalid Input", message: "Please enter a positive number of hours.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            let titleFont = UIFont.boldSystemFont(ofSize: 20)
            let messageFont = UIFont.boldSystemFont(ofSize: 16)
            let attributedTitle = NSAttributedString(string: "Invalid Input", attributes: [.font: titleFont])
            let attributedMessage = NSAttributedString(string: "Please enter a positive number of hours.", attributes: [.font: messageFont])
            alert.setValue(attributedTitle, forKey: "attributedTitle")
            alert.setValue(attributedMessage, forKey: "attributedMessage")
            
            present(alert, animated: true) {
                print("Alert dialog presented")
                self.logger.info("Alert dialog presented")
            }
            notificationInterval = 4.0
            intervalTextField.text = "4"
            return
        }
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        scheduleNotifications()
        startTimer()
    }
    
    // Handle Cancel Notifications button
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        // Cancel all pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Stop the timer and reset state
        timer?.invalidate()
        timer = nil
        nextNotificationDate = nil
        updateTimeLabel() // Reset time label to --:--:--
        
        // Log the cancellation
        print("All notifications canceled via cancelButtonTapped")
        logger.info("All notifications canceled via cancelButtonTapped")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        DispatchQueue.main.async {
            self.view.endEditing(true)
            print("Keyboard dialog dismissed via touchesBegan")
            self.logger.info("Keyboard dialog dismissed via touchesBegan")
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        print("Keyboard dialog dismissed via textFieldShouldReturn")
        logger.info("Keyboard dialog dismissed via textFieldShouldReturn")
        return true
    }
    
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        let category = UNNotificationCategory(identifier: "customNotification", actions: [], intentIdentifiers: [], options: [])
        center.setNotificationCategories([category])
        
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
                self.logger.error("Error requesting notification permission: \(error)")
            }
        }
    }
    
    func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "🔔 REMINDER 🔔"
        content.subtitle = "Time to Check In!"
        content.body = "Your \(notificationInterval)-HOUR Notification!"
        content.sound = .default
        content.categoryIdentifier = "customNotification"
        
        let intervalInSeconds = notificationInterval * 3600
        nextNotificationDate = Date().addingTimeInterval(intervalInSeconds)
        
        for i in 0..<24 {
            let triggerDate = Date().addingTimeInterval(intervalInSeconds * Double(i + 1))
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(identifier: "notification_\(i)", content: content, trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                    self.logger.error("Error scheduling notification: \(error)")
                }
            }
        }
    }
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimeLabel()
        }
    }
    
    func updateTimeLabel() {
        guard let nextDate = nextNotificationDate else {
            timeLabel.text = "Time until next notification: --:--:--"
            return
        }
        
        let now = Date()
        if nextDate > now {
            let timeInterval = nextDate.timeIntervalSince(now)
            let hours = Int(timeInterval) / 3600
            let minutes = (Int(timeInterval) % 3600) / 60
            let seconds = Int(timeInterval) % 60
            timeLabel.text = String(format: "Time until next notification: %02d:%02d:%02d", hours, minutes, seconds)
        } else {
            nextNotificationDate = nextNotificationDate?.addingTimeInterval(notificationInterval * 3600)
            updateTimeLabel()
        }
    }
}
