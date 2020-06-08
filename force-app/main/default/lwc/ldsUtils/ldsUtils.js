/**
 * Reduces one or more LDS errors into a string[] of error messages.
 * @param {FetchResponse|FetchResponse[]} errors
 * @return {String[]} Error messages
 */
export function reduceErrors(errors) {
    if (!Array.isArray(errors)) {
        errors = [errors];
    }

    return (
        errors
            // Remove null/undefined items
            .filter(error => !!error)
            // Extract an error message
            .map(error => {
                // UI API read errors
                if (Array.isArray(error.body)) {
                    return error.body.map(e => e.message);
                }
                // UI API DML, Apex and network errors
                else if (error.body && typeof error.body.message === 'string') {
                    return error.body.message;
                }
                // JS errors
                else if (typeof error.message === 'string') {
                    return error.message;
                }
                // Unknown error shape so try HTTP status text
                return error.statusText;
            })
            // Flatten
            .reduce((prev, curr) => prev.concat(curr), [])
            // Remove empty strings
            .filter(message => !!message)
    );
}

export function showSnackbar(component, type, header, message) {
    let div = component.template.querySelector('.snackbar');

    if(type === 'success') {
        div.classList.add('success');
    }
    else if(type === 'failure') {
        div.classList.add('failure');
    }
    component.snackbarHeaderText = header;
    component.snackbarMessageText = message;
    div.classList.add('show');
    setTimeout(function() { 
        div.classList.remove('show'); 
        div.classList.remove('success'); 
        div.classList.remove('failure'); 
    }, 4000);
  }
