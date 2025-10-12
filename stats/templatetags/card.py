from django import template
from django.utils.html import format_html

register = template.Library()

@register.tag(name="card")
def do_card(parser, token):
    nodelist = parser.parse(('endcard',))
    parser.delete_first_token()
    return CardNode(nodelist)

class CardNode(template.Node):
    def __init__(self, nodelist):
        self.nodelist = nodelist

    def render(self, context):
        content = self.nodelist.render(context)
        return format_html(
            '<div class="card"><div class="card-body">{}</div></div>',
            content
        )
