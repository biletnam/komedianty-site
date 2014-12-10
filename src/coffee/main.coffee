console.log 'foobar'



# $('#playbill .date-block .date').fitText(1.2, { minFontSize: '25px', maxFontSize: '100px' })


$("#playbill .calendar a").click (e) ->
	e.preventDefault()
	unless $(this).attr("class") is "active"
		$("#playbill .calendar a").removeClass "active"
		$(this).addClass "active"
		unless $("#playbill .event").attr("class") is "active"
			$("#playbill .event").addClass "active"
			unless $($(this).attr("href")).attr("class") is "active"
				$("#playbill .event").removeClass "active"
				$($(this).attr("href")).addClass "active"
	else
		$($(this).attr("href")).removeClass "active"
		$(this).removeClass "active"
		$("#playbill .event").removeClass "active"



$(".secondary-navigation a").click (e) ->
	e.preventDefault()
	unless $(this).attr("class") is "active"
		$(".secondary-navigation a").removeClass "active"
		$(this).addClass "active"
		unless $(".content .section").attr("class") is "active"
			$(".content .section").addClass "active"
			unless $($(this).attr("href")).attr("class") is "active"
				$(".content .section").removeClass "active"
				$($(this).attr("href")).addClass "active"
	else
		$($(this).attr("href")).removeClass "active"
		$(this).removeClass "active"
		$(".content .section").removeClass "active"