import asyncio
from aiogram import Bot, Dispatcher
from config_reader import config
from handlers.handlers import *
from redisdb import *
from scheldule import *
import aiocron
import random

# Запуск бота
async def main():
    bot = Bot(token=config.bot_token.get_secret_value() , parse_mode='HTML')
    dp = Dispatcher()
    dp.include_router(router)

    # Альтернативный вариант регистрации роутеров по одному на строку
    # dp.include_router(questions.router)
    # dp.include_router(different_types.router)

    # Запускаем бота и пропускаем все накопленные входящие
    # Да, этот метод можно вызвать даже если у вас поллинг
    await bot.delete_webhook(drop_pending_updates=True)
    await dp.start_polling(bot)


    chat_id = 921953226#личный ччат со мной можно заменить на свой

    @aiocron.crontab("05 13 * * 2")# время запуска опроса
    async def start_poll():
        markup = ReplyKeyboardRemove()
        poll_text = "Всем привет✌🏻, в эфире наша еженедельная программа по наработке социального капитала!🥳 Примешь участие в нашем празднике жизни? ☺️🎉(Досрочно завершить голосование /pairs)"
        options = ["✅ Да", "❌ Нет, в другой раз"]
        await bot.send_poll(
            chat_id=chat_id,
            question=poll_text,
            options=options,
            is_anonymous=False,  # Устанавливает опрос как неанонимный
            reply_markup=markup
        )

    @aiocron.crontab("25 14 * * 1-5") # время ежедневной рассылки расписания и google calendar
    async def schedule_daily_broadcast():
        text = send_schedule()
        subscribers = await load_list_from_redis(redis_url, key = 'chats')
        for subscriber in subscribers:
            await bot.send_message(subscriber, text)


    @aiocron.crontab("00 15 * * 3") # создание случайных пар по результатам опроса
    async def create_pairs():
        yes_users = await load_dict_from_redis(redis_url, key)
        if not yes_users:
            await bot.send_message(chat_id, "Нет активных опросов.")
            return

        poll_id = list(yes_users.keys())[-1]  # Получаем последний опрос

        users = yes_users[poll_id]
        
        if len(users) < 2:
            await bot.send_message(chat_id, "Недостаточно участников для создания пар.")
            return

        pair_text = f"На этой неделе за 🧀 и 🍷 встретятся:\n\n"
        while len(users)>=2:
                pair = random.sample(users, 2)
                pair_text += f"• {' и '.join(['@' + username for username in pair])}\n"
                users = [user for user in users if user not in pair]
                if len(users) == 3:
                        triple = random.sample(users, 3)
                        pair_text += f"• {' и '.join(['@' + username for username in triple])}\n"



        pair_text += "\nДоговоритесь об удобном формате встречи и найдите отклик в сердцах друг друга ❤️!"
        pair_text += "\n\n[DOING LINK](MadeByZealot)"

        await bot.send_message(chat_id, pair_text)


if __name__ == "__main__":
    asyncio.run(main())