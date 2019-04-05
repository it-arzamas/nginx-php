module.exports = {
    'cURL' : function (client) {
        const content = 'Request forbidden by administrative rules. Please make sure your request has a User-Agent header (http://developer.github.com/v3/#user-agent-required). Check https://developer.github.com for other possible causes.';

        client
            .url('http://localhost/tests/curl')
            .assert.containsText('body', content)
            .end();
    },
    'getimagesize' : function (client) {
        const content = 'array(6) { [0]=> int(256) [1]=> int(256) [2]=> int(3) [3]=> string(24) "width="256" height="256"" ["bits"]=> int(4) ["mime"]=> string(9) "image/png" }';

        client
            .url('http://localhost/tests/getimagesize')
            .assert.containsText('body', content)
            .end();
    }
};
