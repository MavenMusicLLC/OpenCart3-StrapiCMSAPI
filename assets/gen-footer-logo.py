#!/usr/bin/env python3
"""Generate footer SVG banner using ElementTree to avoid JSON escaping issues."""
import xml.etree.ElementTree as ET

NS = 'http://www.w3.org/2000/svg'
ET.register_namespace('', NS)

def attrs(**kw):
    return {k: str(v) for k, v in kw.items() if v is not None}

svg = ET.Element('svg', attrs(
    xmlns=NS, viewBox='0 0 400 80', role='img',
    **{'aria-label': 'Maven Music Network - OpenCart Bundle System'}
))

# Defs
defs = ET.SubElement(svg, 'defs')
g = ET.SubElement(defs, 'linearGradient', attrs(id='g', x1='0%', y1='0%', x2='100%', y2='0%'))
stops = [
    ('0%', '#d3b65f'), ('18%', '#f2df88'), ('31%', '#d0ab4a'), ('48%', '#b47a13'),
    ('56%', '#fff4a7'), ('64%', '#c79522'), ('78%', '#ecd879'), ('84%', '#fff5a9'),
    ('93%', '#d0a432'), ('100%', '#b87912'),
]
for off, col in stops:
    ET.SubElement(g, 'stop', attrs(offset=off, **{'stop-color': col}))

gs = ET.SubElement(defs, 'linearGradient', attrs(id='gs', x1='0%', y1='0%', x2='100%', y2='0%'))
for off, col in [('0%', '#d3b65f'), ('100%', '#d3b65f')]:
    ET.SubElement(gs, 'stop', attrs(offset=off, **{'stop-color': col, 'stop-opacity': '0.4'}))

# Background
ET.SubElement(svg, 'rect', attrs(x='0', y='0', width='400', height='80', rx='8', fill='#0a0a0a', stroke='url(#gs)', **{'stroke-width': '1'}))

# Stacked boxes icon
icon = ET.SubElement(svg, 'g', attrs(transform='translate(16, 16)'))
for i, (x, y) in enumerate([(0, 32), (8, 16), (16, 0)]):
    ET.SubElement(icon, 'rect', attrs(x=x, y=y, width=40, height=26, rx=3, fill='#1a1a1a', stroke='url(#g)', **{'stroke-width': '1.5'}))
    ET.SubElement(icon, 'rect', attrs(x=x+5, y=y+6, width=30, height=3, rx=1.5, fill='url(#g)', opacity='0.7'))
    ET.SubElement(icon, 'rect', attrs(x=x+5, y=y+12, width=20, height=3, rx=1.5, fill='url(#g)', opacity='0.4'))

# Plus circle
ET.SubElement(icon, 'circle', attrs(cx='56', cy='45', r='10', fill='url(#g)'))
ET.SubElement(icon, 'path', attrs(d='M56 39 L56 51 M50 45 L62 45', stroke='#0a0a0a', **{'stroke-width': '2.5', 'stroke-linecap': 'round'}))

# Text
ET.SubElement(svg, 'text', attrs(x='80', y='34', **{'font-family': "'Maven Pro','Segoe UI',sans-serif", 'font-weight': '700', 'font-size': '18', 'fill': 'url(#g)', 'letter-spacing': '2'})).text = 'MAVEN MUSIC'
ET.SubElement(svg, 'text', attrs(x='80', y='54', **{'font-family': "'Maven Pro','Segoe UI',sans-serif", 'font-weight': '500', 'font-size': '10', 'fill': '#888', 'letter-spacing': '3'})).text = 'OPENCART + STRAPI CMS'
ET.SubElement(svg, 'line', attrs(x1='80', y1='60', x2='380', y2='60', stroke='url(#gs)', **{'stroke-width': '0.5', 'opacity': '0.4'}))
ET.SubElement(svg, 'text', attrs(x='80', y='72', **{'font-family': "'Maven Pro','Segoe UI',sans-serif", 'font-weight': '400', 'font-size': '8', 'fill': '#666', 'letter-spacing': '2'})).text = 'PRODUCT BUNDLE SYSTEM'

tree = ET.ElementTree(svg)
tree.write('/var/www/vhosts/noxhosting.cloud/OpenCart3-StrapiCMSAPI/assets/logo-footer.svg',
           encoding='unicode', xml_declaration=False)
print('logo-footer.svg generated')
