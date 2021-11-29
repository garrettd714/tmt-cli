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
    # LOGGER.info('Subscribed to: {}'.format(symbols.split(',')))

    # Update the bid/ask via TMT-CLI
    streamer_symbols = symbols.split(',')
    async for item in streamer.listen():
        if streamer_symbols:
            for data in item.data:
                try:
                    streamer_symbols.remove(data['eventSymbol'])
                    system('tmt tasty_stream {} --bid={} --ask={}'.format(data['eventSymbol'], data['bidPrice'], data['askPrice']))
                    if not streamer_symbols:
                        break
                except:
                    print('.', end='')
                    continue
                # LOGGER.info('{} removed, symbols: {}'.format(data['eventSymbol'], streamer_symbols))
                # LOGGER.info('Symbol: {}\tBid: {}\tAsk {}'.format(data['eventSymbol'], data['bidPrice'], data['askPrice']))
        else:
            # LOGGER.info('All symbols have updated.')
            system('tmt tasty_refresh')
            break


def main():
    tasty_client = tasty_session.create_new_session(environ.get('TW_USER', ""), environ.get('TW_PASSWORD', ""))

    streamer = DataStreamer(tasty_client)
    # LOGGER.info('Streamer token: %s' % streamer.get_streamer_token())
    loop = asyncio.get_event_loop()

    try:
        loop.run_until_complete(main_loop(tasty_client, streamer))
    except Exception:
        LOGGER.exception('Exception in streamer')
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
