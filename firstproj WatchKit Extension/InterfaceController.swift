//
//  InterfaceController.swift
//  firstproj WatchKit Extension
//
//  Created by 武田由美 on 2016/02/03.
//  Copyright © 2016年 武田由美. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class InterfaceController: WKInterfaceController{
    
    @IBOutlet var myLabel: WKInterfaceLabel!
   // var count=0
    @IBOutlet var button: WKInterfaceButton!
    
    let healthStore = HKHealthStore()
    var workoutSession:HKWorkoutSession?
    var heartRateQuery:HKQuery?
    let heartRateUnit = HKUnit(fromString: "count/min")
    let heartRateType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
    
    var isRunning = false;
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    }
    
    override func willActivate() {
        super.willActivate()
        
        guard HKHealthStore.isHealthDataAvailable() else {
            myLabel.setText("not available")
            return
        }
        
        let dataTypes = Set([heartRateType])
        
        healthStore.requestAuthorizationToShareTypes(nil, readTypes: dataTypes) { (success, error) -> Void in
            guard success else {
                self.myLabel.setText("not allwed")
                return
            }
        }
    }
    
    override func didDeactivate() {
        super.didDeactivate()
    }
    
    // =========================================================================
    // MARK: - Actions
    @IBAction func fetchBtnTapped(){
        myLabel.setText("heart rate")
//        guard heartRateQuery == nil else { return }
//        
//        if heartRateQuery == nil {
//            //start
//            heartRateQuery = self.createStreamingQuery()
//            healthStore.executeQuery(self.heartRateQuery!)
//            button.setTitle("Stop")
//        }
//        else {
//            //stop
//            healthStore.stopQuery(self.heartRateQuery!)
//            heartRateQuery = nil
//            button.setTitle("Start")
//        }
        //測定スタート
        if isRunning == false {
            //workoutSessionを作成
            self.workoutSession = HKWorkoutSession(activityType: HKWorkoutActivityType.Other, locationType: HKWorkoutSessionLocationType.Unknown)
//            self.workoutSession!.delegate = self
            
            //修正START 2015/12/12
            //workoutSessionをスタート。
            self.healthStore.startWorkoutSession(self.workoutSession!)
            //修正END
            
            //測定ストップ
        }else if isRunning == true {
            //修正START 2015/12/12
            //workoutSessionをストップ。
            self.healthStore.endWorkoutSession(self.workoutSession!)
            //修正END
        }
    }
    
    
    // =========================================================================
    // MARK: - Private
    
    private func createStreamingQuery() -> HKQuery {
        let predicate = HKQuery.predicateForSamplesWithStartDate(NSDate(), endDate: nil, options: .None)
        
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)){ (query, samples, deleteObjects, anchor, error) -> Void in
            self.addSamples(samples)
        }
        query.updateHandler = { (query, samples, deletedObjects, anchor, error) -> Void in
            self.addSamples(samples)
        }
        
        return query
    }
    
    private func addSamples(samples: [HKSample]?){
        guard let samples = samples as? [HKQuantitySample] else { return }
        guard let quantity = samples.last?.quantity else { return }
        myLabel.setText("\(quantity.doubleValueForUnit(heartRateUnit))")
    }
    
    
    
    
    
    
    
    
    /*@IBAction func tapBtn() {
        //カウントアップして表示する
        count++
        myLabel.setText("\(count)")
    }*/

/*    @IBAction func CountDown() {
        //カウントダウンして表示する
        count--
        myLabel.setText("hello")
        myLabel.setText("\(count)")
    }*/
//    override func awakeWithContext(context: AnyObject?) {
//        super.awakeWithContext(context)
//        
//        // Configure interface objects here.
//        if HKHealthStore.isHealthDataAvailable() != true {
//            print("not available")
//            return
//        }
//        
//        let typesToRead = Set([
//            HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
//            ])
//        
//        //HealthKitへのアクセス許可をユーザーへ求める
//        self.healthStore.requestAuthorizationToShareTypes(nil, readTypes: typesToRead){success,error in
//            print("requestAuthorizationToShareTypes: \(success)")
//        }
//    }
//
//        override func willActivate() {
//        // This method is called when watch view controller is about to be visible to user
//        super.willActivate()
//    }
//
//    override func didDeactivate() {
//        // This method is called when watch view controller is no longer visible
//        super.didDeactivate()
//    }
//    
//    @IBAction func btnTapped(){
//        //測定スタート
//        if isRunning == false{
//            //workoutSessionを作成
//            self.workoutSession = HKWorkoutSession(activityType: HKWorkoutActivityType.Other, locationType: <#T##HKWorkoutSessionLocationType#>.Unknown)
//            self.workoutSession!.delegate = self as? HKWorkoutSessionDelegate
//            //workoutSessionをスタート
//            self.healthStore.startWorkoutSession(self.workoutSession!)
//        //測定ストップ
//        }else if isRunning == true {
//            self.healthStore.endWorkoutSession(self.workoutSession!)
//        }
//    }
//    
    /*デリゲートメソッド*/
    //workoutSessionの状態が変化した時に呼ばれる
    func workoutSession(workoutSession: HKWorkoutSession,didChangToState toState:HKWorkoutSessionState,
        fromState:HKWorkoutSessionState,date:NSDate){
            switch toState{
            case .Running:
//                print("workoutSession: .Running")
                myLabel.setText("workoutSession: .Running")
                self.heartRateQuery = createHeartRateStreamingQuery(date)
                self.healthStore.executeQuery(self.heartRateQuery!)
                self.button.setTitle("STOP")
                self.isRunning = true
                
            case .Ended:
//                print("workoutSession: .Ended")
                myLabel.setText("workoutSession: .Ended")
                self.healthStore.stopQuery(self.heartRateQuery!)
                self.myLabel.setText("---")
                self.button.setTitle("START")
                self.isRunning = false
            
            default:
//                print("Unexpected workout session state \(toState)")
                myLabel.setText("Unexpected workout session state \(toState)")
                
            }
    }
    

    //エラーが発生した時に呼ばれる
    func workoutSession(workoutSession: HKWorkoutSession,didFailWithError error:NSError){
        //...
    }
    
    func createHeartRateStreamingQuery(workoutStartDate: NSDate) ->HKQuery{
        let sampleType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)
        let heartRateQuery = HKAnchoredObjectQuery(type: sampleType!, predicate: nil, anchor: nil, limit: 0){
            (query, samokeObjects, DelObjects,newAnchor,error) -> Void in
        }
        
        //アップデートハンドラーを設定
        //心拍数情報が更新されると呼ばれる
        //sampleコードの続きを打てばOK！
        heartRateQuery.updateHandler = {(query,samples,deleteObjects,newAnchor,error) -> Void in
        self.updateHeartRate(samples)
        }
        
        return heartRateQuery
    }
    
    //アップデートハンドラー
    func updateHeartRate(samples: [HKSample]?){
        //心拍数を取得
        guard let heartRateSamples = samples as?[HKQuantitySample] else {return}
        let sample = heartRateSamples.first
        let value = Int(sample!.quantity.doubleValueForUnit(self.heartRateUnit))
        myLabel.setText(String(value))

}
    
    
    /*HeartKitへのアクセス許可を取得するクラスを追加する！
    sampleコードの続き*/
    
    

}
