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

$("#playbill-page .playbill-navigation a").click (e) ->
	e.preventDefault()
	unless $(this).attr("class") is "active"
		$("#playbill-page .playbill-navigation a").removeClass "active"
		$(this).addClass "active"
		unless $("#playbill-page .playbill-list .section").attr("class") is "active"
			$("#playbill-page .playbill-list .section").addClass "active"
			unless $($(this).attr("href")).attr("class") is "active"
				$("#playbill-page .playbill-list .section").removeClass "active"
				$($(this).attr("href")).addClass "active"
	else
		$($(this).attr("href")).removeClass "active"
		$(this).removeClass "active"
		$("#playbill-page .playbill-list .section").removeClass "active"


$("#troupe-page .troupe-navigation a").click (e) ->
	e.preventDefault()
	unless $(this).attr("class") is "active"
		$("#troupe-page .troupe-navigation a").removeClass "active"
		$(this).addClass "active"
		unless $("#troupe-page .troupe-list .section").attr("class") is "active"
			$("#troupe-page .troupe-list .section").addClass "active"
			unless $($(this).attr("href")).attr("class") is "active"
				$("#troupe-page .troupe-list .section").removeClass "active"
				$($(this).attr("href")).addClass "active"
	else
		$($(this).attr("href")).removeClass "active"
		$(this).removeClass "active"
		$("#troupe-page .troupe-list .section").removeClass "active"