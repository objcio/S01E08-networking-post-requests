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
}


struct Resource<A> {
    let url: NSURL
    let method: HttpMethod<NSData>
    let parse: (NSData) -> A?
}

extension Resource {
    init(url: NSURL, method: HttpMethod<AnyObject> = .get, parseJSON: (AnyObject) -> A?) {
        self.url = url
        switch method {
        case .get:
            self.method = .get
        case .post(let json):
            let bodyData = try! NSJSONSerialization.dataWithJSONObject(json, options: [])
            self.method = .post(bodyData)
        }
        self.parse = { data in
            let json = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
            return json.flatMap(parseJSON)
        }
    }
}


func pushNotification(token: String) -> Resource<Bool> {
    let url = NSURL(string: "")!
    let dictionary = ["token": token]
    return Resource(url: url, method: .post(dictionary), parseJSON: { _ in
        return true
    })
}


final class Webservice {
    func load<A>(resource: Resource<A>, completion: A? -> ()) {
        NSURLSession.sharedSession().dataTaskWithURL(resource.url) { data, _, _ in
            completion(data.flatMap(resource.parse))
            }.resume()
    }
}
