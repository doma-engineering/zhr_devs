const assert = require('assert/strict');

const WDIO_URL = process.env.WDIO_URL || 'localhost';

const punch = '\n================\n';

describe('wdio', () => {
    it('runs tests', async () => {
        return true;
    });
    it('has access to browser object', async () => {
        assert(typeof browser === 'object');
        try {
            await browser.url(`http://${WDIO_URL}:3000`);
        } catch (e) {
            assert.equal(e.name, 'unknown error'); // Nice meme, wdio! Love it when errors get forgotten.
            // That said, if url isn't in browser and isn't a funciton, we'll get a TypeError, so this test isn't completely useless.

            // assert(JSON.stringify(e).includes('net::ERR_CONNECTION_REFUSED'));
            // ^ This doesn't work
        }
    });
});
