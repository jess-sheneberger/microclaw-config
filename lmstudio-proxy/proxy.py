#!/usr/bin/env python3
import json
import logging
import time

import aiohttp
from aiohttp import web

UPSTREAM = "http://host.docker.internal:1234"

logging.basicConfig(
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
    level=logging.INFO,
)
log = logging.getLogger("lmstudio-proxy")

SKIP_REQ_HEADERS = {"host", "content-length", "transfer-encoding"}
SKIP_RESP_HEADERS = {"content-length", "transfer-encoding"}


async def proxy(request: web.Request) -> web.StreamResponse:
    t0 = time.monotonic()

    body = await request.read()

    model = "?"
    try:
        payload = json.loads(body)
        model = payload.get("model", "?")
    except Exception:
        pass

    upstream_url = f"{UPSTREAM}{request.path_qs}"
    req_headers = {
        k: v for k, v in request.headers.items()
        if k.lower() not in SKIP_REQ_HEADERS
    }

    connector = aiohttp.TCPConnector()
    async with aiohttp.ClientSession(connector=connector) as session:
        async with session.request(
            method=request.method,
            url=upstream_url,
            headers=req_headers,
            data=body,
            timeout=aiohttp.ClientTimeout(total=600),
        ) as upstream:
            resp_headers = {
                k: v for k, v in upstream.headers.items()
                if k.lower() not in SKIP_RESP_HEADERS
            }
            response = web.StreamResponse(
                status=upstream.status,
                headers=resp_headers,
            )
            await response.prepare(request)

            ttft: float | None = None
            chunks = 0

            async for chunk in upstream.content.iter_any():
                if chunk:
                    if ttft is None:
                        ttft = time.monotonic() - t0
                    chunks += 1
                    await response.write(chunk)

            total = time.monotonic() - t0
            log.info(
                "%-40s  status=%d  ttft=%6.3fs  total=%7.3fs  chunks=%d",
                model, upstream.status, ttft or 0.0, total, chunks,
            )

            await response.write_eof()
            return response


app = web.Application(client_max_size=64 * 1024 * 1024)
app.router.add_route("*", "/{path_info:.*}", proxy)

if __name__ == "__main__":
    log.info("lmstudio-proxy listening on :1290 → %s", UPSTREAM)
    web.run_app(app, host="0.0.0.0", port=1290, access_log=None)
