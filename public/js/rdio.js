var qs = require("querystring"),
    url = require("url"),
    http = require("http"),
    crypto = require("crypto");

function om(consumer, urlString, params, token, method, realm, timestamp, nonce) {
    params = params || [];
    method = (method || "POST").toUpperCase();

    // Coerce params to array of [key, value] pairs.
    if (!Array.isArray(params)) {
        var paramsArray = [];

        for (var key in params) {
            paramsArray.push([key, params[key]]);
        }

        params = paramsArray;
    }

    var parsed = url.parse(urlString, true);

    // Add query params.
    if (parsed.query) {
        for (var key in parsed.query) {
            params.push([key, parsed.query[key]]);
        }
    }

    // Generate nonce and timestamp if they weren't provided
    if (typeof timestamp == "undefined" || timestamp == null) {
        timestamp = Math.round(new Date().getTime() / 1000).toString();
    }
    if (typeof nonce == "undefined" || nonce == null) {
        nonce = Math.round(Math.random() * 1000000).toString();
    }

    // Add OAuth params.
    params.push(["oauth_version", "1.0"]);
    params.push(["oauth_timestamp", timestamp]);
    params.push(["oauth_nonce", nonce]);
    params.push(["oauth_signature_method", "HMAC-SHA1"]);
    params.push(["oauth_consumer_key", consumer[0]]);

    // Calculate the hmac key.
    var hmacKey = consumer[1] + "&";

    // If a token was provided, add it to the params and hmac key.
    if (typeof token != "undefined" && token != null) {
        params.push(["oauth_token", token[0]]);
        hmacKey += token[1];
    }

    // Sort lexicographically, first by key then by value.
    params.sort();

    // Calculate the OAuth signature.
    var paramsString = params.map(function (param) {
        return qs.escape(param[0]) + "=" + qs.escape(param[1]);
    }).join("&");

    var urlBase = url.format({
        protocol: parsed.protocol || "http:",
        hostname: parsed.hostname.toLowerCase(),
        pathname: parsed.pathname
    });

    var signatureBase = [
        method,
        qs.escape(urlBase),
        qs.escape(paramsString)
    ].join("&");

    var hmac = crypto.createHmac("sha1", hmacKey);
    hmac.update(signatureBase);

    var oauthSignature = hmac.digest("base64");

    // Build the Authorization header.
    var headerParams = [];

    if (realm) {
        headerParams.push(["realm", realm]);
    }

    headerParams.push(["oauth_signature", oauthSignature]);

    // Restrict header params to oauth_* subset.
    var oauthParams = ["oauth_version", "oauth_timestamp", "oauth_nonce",
        "oauth_signature_method", "oauth_signature", "oauth_consumer_key",
        "oauth_token"];

    params.forEach(function (param) {
        if (oauthParams.indexOf(param[0]) != -1) {
            headerParams.push(param);
        }
    });

    var header = "OAuth " + headerParams.map(function (param) {
        return param[0] + '="' + param[1] + '"';
    }).join(", ");

    return header;
}

window.Rdio = function Rdio(consumer, token) {
    this.consumer = consumer;
    this.token = token;
}

Rdio.prototype.beginAuthentication = function beginAuthentication(callbackUrl, callback) {
    var self = this;

    this._signedPost("http://api.rdio.com/oauth/request_token", {
        oauth_callback: callbackUrl
    }, function (err, body) {
        if (err) {
            callback(err, null);
        } else {
            var parsed = qs.parse(body);
            var token = [parsed.oauth_token, parsed.oauth_token_secret];
            var authUrl = parsed.login_url + "?oauth_token=" + parsed.oauth_token;
            // Save the token.
            self.token = token;
            // Call the callback with a URL the app can use to auth.
            callback(null, authUrl);
        }
    });
}

Rdio.prototype.completeAuthentication = function completeAuthentication(verifier, callback) {
    var self = this;

    this._signedPost("http://api.rdio.com/oauth/access_token", {
        oauth_verifier: verifier
    }, function (err, body) {
        if (err) {
            callback(err);
        } else {
            var parsed = qs.parse(body);
            var token = [parsed.oauth_token, parsed.oauth_token_secret];
            // Save the token.
            self.token = token;
            // Call the callback.
            callback(null);
        }
    });
}

Rdio.prototype.call = function call(method, params, callback) {
    if (typeof params == "function") {
        callback = params;
        params = null;
    }

    var copy = {};

    if (params) {
        for (var param in params) {
            copy[param] = params[param];
        }
    }

    copy.method = method;

    this._signedPost("http://api.rdio.com/1/", copy, function (err, body) {
        if (err) {
            callback(err, null);
        } else {
            callback(null, JSON.parse(body));
        }
    });
}

Rdio.prototype._signedPost = function signedPost(urlString, params, callback) {
    var auth = om(this.consumer, urlString, params, this.token);
    var parsed = url.parse(urlString);
    var content = qs.stringify(params);

    var req = http.request({
        method: "POST",
        host: parsed.host,
        port: parsed.port || "80",
        path: parsed.pathname,
        headers: {
            "Authorization": auth,
            "Content-Type": "application/x-www-form-urlencoded",
            "Content-Length": content.length.toString()
        }
    }, function (res) {
        var body = "";

        res.setEncoding("utf8");

        res.on("data", function (chunk) {
            body += chunk;
        });

        res.on("end", function () {
            callback(null, body);
        });
    });

    req.on("error", function (err) {
        callback(err);
    });

    req.end(content);
}

