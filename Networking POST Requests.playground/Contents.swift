import UIKit


typealias JSONDictionary = [String: AnyObject]


enum HttpMethod<Body> {
    case get
    case post(Body)
}

extension HttpMethod {
    var method: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        }
    }

    func map<B>(f: (Body) -> B) -> HttpMethod<B> {
        switch self {
        case .get: return .get
        case .post(let body):
            return .post(f(body))
        }
        
    }
}


struct Resource<A> {
    let url: NSURL
    let method: HttpMethod<NSData>
    let parse: (NSData) -> A?
}

extension Resource {
    init(url: NSURL, method: HttpMethod<AnyObject> = .get, parseJSON: (AnyObject) -> A?) {
        self.url = url
        self.method = method.map { json in
            try! NSJSONSerialization.dataWithJSONObject(json, options: [])
        }
        self.parse = { data in
            let json = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
            return json.flatMap(parseJSON)
        }
    }
}


func pushNotification(token: String) -> Resource<Bool> {
    let url = NSURL(string: "Some test URL")!
    let dictionary = ["token": token]
    return Resource(url: url, method: .post(dictionary), parseJSON: { _ in
        return true
    })
}


extension NSMutableURLRequest {
    convenience init<A>(resource: Resource<A>) {
        self.init(URL: resource.url)
        HTTPMethod = resource.method.method
        if case let .post(data) = resource.method {
            HTTPBody = data
        }
    }
}


final class Webservice {
    func load<A>(resource: Resource<A>, completion: A? -> ()) {
        let request = NSMutableURLRequest(resource: resource)
        NSURLSession.sharedSession().dataTaskWithRequest(request) { data, _, _ in
            completion(data.flatMap(resource.parse))
        }.resume()
    }
}
