import consumer from './consumer'

consumer.subscriptions.create('WhatsappMessagesChannel', {
	received(data) {
		const messageRow = document.getElementById(`message-${data.id}`)
		if (messageRow) {
			const statusElement = messageRow.querySelector('.status')
			if (statusElement) {
				statusElement.innerText = data.status
			}
			const progressElement = messageRow.querySelector('.progress')
			if (progressElement) {
				progressElement.innerText = `${data.sent_count}/${data.total_count}`
			}
		}
	},
})
