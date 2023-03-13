//
//  ScheduleManager.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 23/09/20.
//

import Foundation

public class ScheduleManager : EventManager {
    
    private let storage:SharedManager = SharedManager(tag: "NotificationSchedule")
    private let pendingShared:SharedManager = SharedManager(tag: "PendingSchedules")    
    private var pendingSchedules:[String:String]
    
    
    // **************************** SINGLETON PATTERN *************************************
    
    static var instance:ScheduleManager?
    public static var shared:ScheduleManager {
        get {
            ScheduleManager.instance =
            ScheduleManager.instance ?? ScheduleManager()
            return ScheduleManager.instance!
        }
    }
    private override init(){
        pendingSchedules = pendingShared.get(referenceKey: "pending") as? [String:String] ?? [:]
    }
    
    // **************************** SINGLETON PATTERN *************************************
    
    public func removeSchedule( id:Int ) -> Bool {
        let referenceKey = String(id)
        for (epoch, scheduledId) in pendingSchedules {
            if (scheduledId == referenceKey) {
                pendingSchedules.removeValue(forKey: epoch)
            }
        }
        updatePendingList()
        return storage.remove(referenceKey: referenceKey)
    }
    
    public func listSchedules() -> [NotificationModel] {
        var returnedList:[NotificationModel] = []
        let dataList = storage.getAllObjects()
        
        for data in dataList {
            let channel:NotificationModel = NotificationModel().fromMap(arguments: data) as! NotificationModel
            returnedList.append(channel)
        }
        
        return returnedList
    }
    
    public func listPendingSchedules(referenceDate:Date) -> [NotificationModel] {
        var returnedList:[NotificationModel] = []
        let referenceEpoch = referenceDate.timeIntervalSince1970.description
        
        for (epoch, id) in pendingSchedules {
            if epoch <= referenceEpoch {
                let notificationModel = getScheduleByKey(id: Int(id)!)
                if notificationModel != nil{
                    returnedList.append(notificationModel!)
                }
            }
        }
        
        return returnedList
    }
    
    public func saveSchedule(notification:NotificationModel, nextDate:Date){
        let referenceKey =  String(notification.content!.id!)
        let epoch =  nextDate.secondsSince1970.description
        
        pendingSchedules[epoch] = referenceKey
        storage.set(notification.toMap(), referenceKey:referenceKey)
        updatePendingList()
    }
    
    public func updatePendingList(){
        pendingShared.set(pendingSchedules, referenceKey:"pending")
    }
    
    public func getEarliestDate() -> Date? {
        var smallest:String?
        
        for (epoch, _) in pendingSchedules {

            if smallest == nil || smallest! > epoch {
                 smallest = epoch
            }
        }
        
        if(smallest == nil){ return nil }
        
        let seconds:Int64 = Int64(smallest!)!
        let smallestDate:Date? = Date(seconds: seconds)
        
        return smallestDate
    }
    
    public func getScheduleByKey( id:Int ) -> NotificationModel? {
        guard let data:[String:Any?] = storage.get(referenceKey: String(id)) else {
          return nil
        }
        return NotificationModel().fromMap(arguments: data) as? NotificationModel
    }
    
    public func isNotificationScheduleActive( channelKey:String ) -> Bool {
        return storage.get(referenceKey: channelKey) != nil
    }
    
    public func cancelAllSchedules() -> Bool {
        storage.removeAll()
        pendingShared.removeAll()
        return true
    }

    public func cancelScheduled(id:Int) -> Bool {
        return storage.remove(referenceKey: String(id))
    }
}
