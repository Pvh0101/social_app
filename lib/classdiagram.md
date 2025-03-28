classDiagram
    class User {
        -uid : string
        -email : string
        -fullName : string
        -gender : string
        -birthDay : datetime
        -phoneNumber : string
        -address : string
        -profileImage : string
        -decs : string
        -lastSeen : datetime
        -createdAt : datetime
        -isOnline : boolean
        -isPrivateAccount : boolean
        -followersCount : int
        -token : string
        +add()
        +update()
        +delete()
        +updateStatus()
        +getById()
        +getByEmail()
    }
    
    class Friendship {
        -friendshipId : string
        -senderId : string
        -receiverId : string
        -isAccepted : boolean
        -createdAt : datetime
        +sendRequest()
        +acceptRequest()
        +rejectRequest()
        +cancelRequest()
        +unfriend()
        +getFriends()
        +getRequests()
    }
    
    class Message {
        -id : string
        -chatId : string
        -senderId : string
        -senderName : string
        -senderAvatar : string
        -content : string
        -type : string
        -mediaUrl : string
        -seenBy : array
        -createdAt : datetime
        +send()
        +delete()
        +markAsSeen()
        +getByChatId()
    }
    
    class Like {
        -likeId : string
        -userId : string
        -postId : string
        -commentId : string
        -createdAt : datetime
        +add()
        +delete()
        +check()
    }
    
    class Notification {
        -id : string
        -senderId : string
        -receiverId : string
        -content : string
        -type : string
        -postId : string
        -commentId : string
        -chatId : string
        -isRead : boolean
        -createdAt : datetime
        -senderName : string
        -senderAvatar : string
        +create()
        +markAsRead()
        +delete()
        +getByUser()
        +getUnread()
    }
    
    class Post {
        -postId : string
        -userId : string
        -content : string
        -fileUrls : array
        -thumbnailUrl : string
        -postType : string
        -createdAt : datetime
        -updatedAt : datetime
        -likeCount : int
        -commentCount : int
        +add()
        +update()
        +delete()
        +getFeed()
        +getByUser()
        +like()
        +unlike()
        +addComment()
    }
    
    class Comment {
        -commentId : string
        -postId : string
        -userId : string
        -content : string
        -likeCount : int
        -createdAt : datetime
        -parentId : string
        +add()
        +update()
        +delete()
        +like()
        +unlike()
        +getReplies()
    }
    
    class Chatroom {
        -id : string
        -members : array
        -admins : array
        -name : string
        -avatar : string
        -isGroup : boolean
        -isPublic : boolean
        -lastMessageId : string
        -lastMessage : string
        -lastMessageType : string
        -lastMessageSenderId : string
        -updatedAt : datetime
        -createdBy : string
        -createdAt : datetime
        +create()
        +update()
        +delete()
        +addMember()
        +removeMember()
        +addAdmin()
        +getOtherUserId()
        +getByUser()
    }
    