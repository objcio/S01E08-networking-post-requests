import UIKit


typealias JSONDictionary = [String: AnyObject]


enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
}

struct Resource<A> {
    let url: NSURL
    let method: HttpMethod
    let body: NSData?
    let parse: (NSData) -> A?
}

//extension Resource {
//    init(url: NSURL, parseJSON: (AnyObject) -> A?) {
//        self.url = url
//        self.parse = { data in
//            let json = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
//            return json.flatMap(parseJSON)
//        }
//    }
//}


final class Webservice {
    func load<A>(resource: Resource<A>, completion: A? -> ()) {
        NSURLSession.sharedSession().dataTaskWithURL(resource.url) { data, _, _ in
            completion(data.flatMap(resource.parse))
            }.resume()
    }
}
