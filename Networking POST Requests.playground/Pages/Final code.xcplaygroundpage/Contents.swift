import Foundation

typealias JSONDictionary = [String: AnyObject]


enum HttpMethod<Body> {
    case get
    case head
    case post(Body)
    case patch(Body)
    case put(Body)
    case delete
    case connect
    case options
    case trace
}

extension HttpMethod {
    var method: String {
        switch self {
        case .get: return "GET"
        case .head: return "HEAD"
        case .post: return "POST"
        case .patch: return "PATCH"
        case .put: return "PUT"
        case .delete: return "DELETE"
        case .connect: return "CONNECT"
        case .options: return "OPTIONS"
        case .trace: return "TRACE"
        }
    }
    
    func map<B>(f: (Body) -> B) -> HttpMethod<B> {
        switch self {
        case .get: return .get
        case .head: return .head
        case .post(let body):
            return .post(f(body))
        case .patch(let body):
            return .patch(f(body))
        case .put(let body):
            return .put(f(body))
        case .delete: return .delete
        case .connect: return .connect
        case .options: return .options
        case .trace: return .trace
        }
    }
}

struct Resource<A> {
    let url: URL
    let method: HttpMethod<Data>
    let parse: (Data) -> A?
}

extension Resource {
    init(url: URL, method: HttpMethod<Any> = .get, parseJSON: @escaping (Any) -> A?) {
        self.url = url
        self.method = method.map { json in
            try! JSONSerialization.data(withJSONObject: json, options: [])
        }
        self.parse = { data in
            let json = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
            return json.flatMap(parseJSON)
        }
    }
}

func pushNotification(token: String) -> Resource<Bool> {
    let url = URL(string: "Some test URL")!
    let dictionary = ["token": token]
    return Resource(url: url, method: .post(dictionary), parseJSON: { _ in
        return true
    })
}

extension URLRequest {
    init<A>(resource: Resource<A>) {
        self.init(url: resource.url)
        httpMethod = resource.method.method
        if case let .post(data) = resource.method {
            httpBody = data
        }
        if case let .patch(data) = resource.method {
            httpBody = data
        }
        if case let .put(data) = resource.method {
            httpBody = data
        }
    }
}

final class Webservice {
    func load<A>(resource: Resource<A>, completion: @escaping (A?) -> ()) {
        let request = URLRequest(resource: resource)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            completion(data.flatMap(resource.parse))
            }.resume()
    }
}
