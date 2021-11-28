import asyncio
import logging
import subprocess
from os import environ, system
from tastyworks.models.session import TastyAPISession
from tastyworks.streamer import DataStreamer
from tastyworks.tastyworks_api import tasty_session

LOGGER = logging.getLogger(__name__)


async def main_loop(session: TastyAPISession, streamer: DataStreamer):
    # Call TMT-CLI for active symbols (dxfeed style)
    symbols = subprocess.getoutput('tmt tasty_dxfeed')
    sub_values = {
        "Quote": symbols.split(',')
    }

    # Subscribe
    await streamer.add_data_sub(sub_values)
    LOGGER.info('Subscribed to: {}'.format(symbols.split(',')))

    # Update the bid/ask via TMT-CLI
    async for item in streamer.listen():
        for data in item.data:
            system('tmt tasty_stream {} --bid={} --ask={}'.format(data['eventSymbol'], data['bidPrice'], data['askPrice']))
            # LOGGER.info('Symbol: {}\tBid: {}\tAsk {}'.format(data['eventSymbol'], data['bidPrice'], data['askPrice']))


def main():
    tasty_client = tasty_session.create_new_session(environ.get('TW_USER', ""), environ.get('TW_PASSWORD', ""))

    streamer = DataStreamer(tasty_client)
    # LOGGER.info('Streamer token: %s' % streamer.get_streamer_token())
    loop = asyncio.get_event_loop()

    try:
        loop.run_until_complete(main_loop(tasty_client, streamer))
    except Exception:
        LOGGER.exception('Exception in main loop')
    except (KeyboardInterrupt, RuntimeError) as e:
        system('tmt tasty_refresh')
        print(' Exit requested')
    finally:
        # find all futures/tasks still running and wait for them to finish
        if loop.is_running():
            pending_tasks = [
                task for task in asyncio.all_tasks() if not task.done()
            ]
            if pending_tasks.size:
                loop.run_until_complete(asyncio.gather(*pending_tasks))


if __name__ == '__main__':
    main()
