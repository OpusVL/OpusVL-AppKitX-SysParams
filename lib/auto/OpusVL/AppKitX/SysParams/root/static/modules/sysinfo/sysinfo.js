$(function() {
    $('.field.field-type').on('change', setFieldType('.field.field-value'));
    $(document).on('input', '.field.field-value', setTypeOptions('.field.field-type'));
    $(document).on('input', '.field.field-value', setAllFields);

    // I can't work with FormFu so I'm doing this.
    // We won't need this in the FB11 version.
    var input = {};
    input.textarea = $('.templates .js-value-textarea').detach();
    input.text = $('.templates .js-value-text').detach();
    input.object = $('.templates .js-value-raw').detach();
    input.boolean = $('.templates .js-value-boolean').detach();
    input.array = $('.templates .js-value-array').detach();

    // Pretend to fire an event
    setFieldType('.field.field-value')({ srcElement: $('.field.field-type :checked')[0] });
    setTypeOptions('.field.field-type')({ srcElement: $('.field.field-value')[0] });

    $(document).on('input', '.field-value-new', function() {
        var $this = $(this);

        $this.prev('.remove').clone().appendTo($this.parent());
        $this.clone().val('').appendTo($this.parent());

        $this
            .removeClass('field-value-new')
            .addClass('field-value-' + ($this.parent().find('input').length - 1))
            .attr('name', 'value');
    });

    $(document).on('click', '.remove', function() { $(this).prev().remove(); $(this).remove() });

    function setFieldType(selector) {
        return function(event) {
            var $field = $(selector);
            var type = event.srcElement.value;

            var $newField = input[type];
            var c = $field.attr('class');
            $field.removeAttr('class');
            $newField.attr('class', c);

            $field.replaceWith($newField);
        }
    }

    function setTypeOptions(selector) {
        return function(event) {
            var $currentTypeField = $(selector).find(':checked');
            var $field = $(event.srcElement);

            // if the JSON field is an object or array it cannot be converted
            if ($currentTypeField.val() == 'json') {
                if ($field.val().match(/^(\{|\[)/)) {
                    $('.field.field-type [value=multi], .field.field-type [value=string').attr('disabled', true);
                }
                else {
                    $('.field.field-type [value=multi], .field.field-type [value=string').attr('disabled', false);
                }
            }
        }
    }

    function setAllFields(event) {
        var $field = $(event.srcElement);
        var val = $field.val();
        var $currentTypeField = $('.field.field-type :checked');


        if ($currentTypeField.val() == 'json') {
            // mid-edit this might fail.
            try {
                val = JSON.parse(val);
                input.multi.val(val);
                input.string.val(val);
            } catch (e) {}
        }
        else {
            input.multi.val(val);
            input.string.val(val);
            input.json.val(JSON.stringify(val));
        }
    }
});
