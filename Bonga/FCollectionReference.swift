//
//  FUser.swift
//  Bonga
//
//  Created by Rony Quail on 03/10/2018.
//  Copyright © 2018 Rony Quail. All rights reserved.
//

import Foundation
import FirebaseFirestore


enum FCollectionReference: String {
    case User
    case Typing
    case Recent
    case Message
    case Group
    case Call
}


func reference(_ collectionReference: FCollectionReference) -> CollectionReference{
    return Firestore.firestore().collection(collectionReference.rawValue)
}

