moment     = require 'moment'

moment().locale('ru-my', {months:["Января","Февраля","Марта","Апреля","Мая","Июня","Июля","Августа","Сентября","Октября","Ноября","Декабря"]})

console.log moment('2014-12-11 19:00:00').locale('ru-my').format('mm')