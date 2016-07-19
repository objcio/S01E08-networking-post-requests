import UIKit


typealias JSONDictionary = [String: AnyObject]


enum HttpMethod {
    case get
    case post(NSData)
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
    let method: HttpMethod
    let parse: (NSData) -> A?
}

extension Resource {
    init(url: NSURL, parseJSON: (AnyObject) -> A?) {
        self.url = url
        self.method = .get
        self.parse = { data in
            let json = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
            return json.flatMap(parseJSON)
        }
    }
}


func pushNotification(token: String) -> Resource<Bool> {
    let url = NSURL(string: "")!
    let dictionary = ["token": token]
    let bodyData = try! NSJSONSerialization.dataWithJSONObject(dictionary, options: [])
    return Resource(url: url, method: .post(bodyData), parse: { _ in
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
