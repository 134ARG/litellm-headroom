"""
Custom LiteLLM entrypoint with Headroom compression callback.

Wraps HeadroomCallback to fix the async_pre_call_hook signature mismatch:
- HeadroomCallback expects: (user_api_key, data, call_type)
- LiteLLM proxy passes:     (user_api_key_dict, cache, data, call_type)
"""

import logging
import litellm
from litellm.integrations.custom_logger import CustomLogger
from headroom.integrations.litellm_callback import HeadroomCallback

# Force headroom logger to print to stdout
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s:%(levelname)s - %(message)s",
)
headroom_logger = logging.getLogger("headroom")
headroom_logger.setLevel(logging.INFO)


class CompatHeadroomCallback(CustomLogger):
    """
    Bridges the signature gap between HeadroomCallback and
    what LiteLLM proxy actually calls.
    """

    def __init__(self):
        super().__init__()
        self._headroom = HeadroomCallback()

    async def async_pre_call_hook(self, user_api_key_dict, cache, data, call_type):
        call_type_str = str(call_type)
        model = data.get("model", "unknown")
        msg_count = len(data.get("messages", []))
        print(
            f"[Headroom] pre_call_hook fired: call_type={call_type_str}, "
            f"model={model}, messages={msg_count}",
            flush=True,
        )

        try:
            result = await self._headroom.async_pre_call_hook(
                user_api_key=str(user_api_key_dict),
                data=data,
                call_type=call_type_str,
            )
            if result is not None:
                new_msg_count = len(result.get("messages", []))
                print(
                    f"[Headroom] compression done: messages {msg_count}→{new_msg_count}",
                    flush=True,
                )
                return result
            else:
                print("[Headroom] returned None, using original data", flush=True)
                return data
        except Exception as e:
            print(f"[Headroom] ERROR in pre_call_hook: {e}", flush=True)
            return data


litellm.callbacks = [CompatHeadroomCallback()]

from litellm.proxy.proxy_cli import run_server

if __name__ == "__main__":
    run_server()
