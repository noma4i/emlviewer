#!/usr/bin/env python3
from email.message import EmailMessage
from email.policy import SMTP
from pathlib import Path
from io import BytesIO
from zipfile import ZipFile, ZIP_DEFLATED
import importlib.util
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'AppStore/demo'
OUT.mkdir(parents=True, exist_ok=True)


def message(subject, sender, recipient):
    m = EmailMessage(policy=SMTP)
    m['From'] = sender
    m['To'] = recipient
    m['Subject'] = subject
    m['Date'] = 'Thu, 16 Apr 2026 14:30:00 +0000'
    return m


def save(m, name):
    for i, part in enumerate(m.walk()):
        if part.is_multipart():
            part.set_boundary('emlviewer-demo-%s-%d' % (name, i))
    (OUT / name).write_bytes(m.as_bytes())


with tempfile.TemporaryDirectory() as tmp:
    art = Path(tmp) / 'landscape.png'
    subprocess.run(['/usr/bin/swift', str(ROOT / 'Scripts/appstore/art.swift'), str(art)], check=True)
    landscape = art.read_bytes()

hero = message('A little more room to think', 'Mira Vale <mira@example.com>', 'Avery Lane <avery@example.com>')
hero.set_content('A fresh perspective for your next project. Explore the April edition of Field Notes.')
hero.add_alternative('''<!doctype html><html><body style="margin:0;background:#f5f3ef;font-family:-apple-system,BlinkMacSystemFont,sans-serif;color:#26343b"><table width="100%" cellpadding="0" cellspacing="0"><tr><td align="center"><table width="600" cellpadding="0" cellspacing="0" style="background:#fff"><tr><td style="padding:32px 44px;font-size:13px;letter-spacing:3px;font-weight:700;color:#416b77">FIELD NOTES &nbsp; / &nbsp; APRIL</td></tr><tr><td><img src="cid:landscape@example.com" width="600" style="display:block;width:100%;height:auto"></td></tr><tr><td style="padding:36px 44px"><p style="font-size:13px;letter-spacing:2px;color:#638a94">A NEW PERSPECTIVE</p><h1 style="font-size:36px;line-height:1.15;margin:12px 0 20px">A little more room to think.</h1><p style="font-size:17px;line-height:1.6;color:#56656a">Good ideas need space. This month, we're making time for the work that matters and finding inspiration in the details.</p><p style="font-size:17px;line-height:1.6;color:#56656a">Take a moment, look around, and see where a fresh perspective can lead.</p><p style="margin-top:30px"><span style="background:#416b77;color:white;padding:14px 22px;border-radius:5px;font-weight:600">Explore the collection &rarr;</span></p></td></tr></table></td></tr></table></body></html>''', subtype='html')
hero.get_payload()[-1].add_related(landscape, maintype='image', subtype='png', cid='<landscape@example.com>')
save(hero, 'field-notes.eml')

plain = message('Notes from the coast', 'Elise M\u00fcller <elise@example.com>', 'Lucie Ren\u00e9 <lucie@example.com>')
plain.set_content('Bonjour Lucie,\n\nMerci pour les belles photos de votre voyage. Le caf\u00e9 pr\u00e8s du port semble magnifique.\n\n\u00c0 bient\u00f4t,\nElise\n')
save(plain, 'plain-text.eml')

travel = message('Your itinerary and travel documents', 'Travel Desk <travel@example.com>', 'Avery Lane <avery@example.com>')
travel.set_content('Hi Avery,\n\nYour travel documents are ready. Please find your itinerary and reference materials attached.\n\nHave a wonderful journey,\nTravel Desk\n')
travel.add_alternative('''<html><body style="font-family:-apple-system,sans-serif;background:#f4f7f8;color:#26343b;padding:28px"><div style="max-width:580px;background:white;padding:32px;border-radius:12px"><p style="color:#668a96;letter-spacing:2px;font-size:13px">YOUR JOURNEY</p><h1 style="font-size:30px">The coast is calling.</h1><p style="font-size:17px;line-height:1.6">Hi Avery, everything is ready for your upcoming trip. Find your itinerary, budget, and reference materials below.</p><div style="background:#edf5f7;padding:20px;border-radius:8px"><strong>Harbor Point</strong><br>May 12 - May 16<br>Four days by the water</div><p style="font-size:17px;line-height:1.6">Have a wonderful journey,<br>Travel Desk</p></div></body></html>''', subtype='html')
spec = importlib.util.spec_from_file_location('sample_msg', ROOT / 'Scripts/gen-sample-msg.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
with tempfile.TemporaryDirectory() as tmp:
    art = Path(tmp) / 'landscape.png'
    art.write_bytes(landscape)
    subprocess.run(['/usr/bin/sips', '-z', '1000', '2400', str(art)], check=True, stdout=subprocess.DEVNULL)
    pdf = Path(tmp) / 'itinerary.pdf'
    subprocess.run(['/usr/bin/swift', str(ROOT / 'Scripts/appstore/itinerary.swift'), str(pdf), str(art)], check=True)
    pdf_data = pdf.read_bytes()
travel.add_attachment(pdf_data, maintype='application', subtype='pdf', filename='itinerary.pdf')
with tempfile.TemporaryDirectory() as tmp:
    jpg = Path(tmp) / 'destination.jpg'
    art = Path(tmp) / 'landscape.png'
    art.write_bytes(landscape)
    subprocess.run(['/usr/bin/sips', '-s', 'format', 'jpeg', str(art), '--out', str(jpg)], check=True, stdout=subprocess.DEVNULL)
    jpg_data = jpg.read_bytes()
    travel.add_attachment(jpg_data, maintype='image', subtype='jpeg', filename='destination.jpg')
buf = BytesIO()
with ZipFile(buf, 'w', ZIP_DEFLATED) as z:
    z.writestr('itinerary.pdf', pdf_data)
    z.writestr('destination.jpg', jpg_data)
    z.writestr('landscape.png', landscape)
travel.add_attachment(buf.getvalue(), maintype='application', subtype='zip', filename='travel-reference.zip')
buf = BytesIO()
with ZipFile(buf, 'w', ZIP_DEFLATED) as z:
    z.writestr('[Content_Types].xml', '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>')
    z.writestr('_rels/.rels', '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>')
    z.writestr('xl/workbook.xml', '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Budget" sheetId="1" r:id="rId1"/></sheets></workbook>')
    z.writestr('xl/_rels/workbook.xml.rels', '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>')
    z.writestr('xl/worksheets/sheet1.xml', '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData><row r="1"><c r="A1" t="inlineStr"><is><t>Travel budget</t></is></c><c r="B1"><v>1200</v></c></row></sheetData></worksheet>')
xlsx_data = buf.getvalue()
travel.add_attachment(xlsx_data, maintype='application', subtype='vnd.openxmlformats-officedocument.spreadsheetml.sheet', filename='budget.xlsx')
save(travel, 'travel.eml')
source = (ROOT / 'Scripts/gen-sample-msg.py').read_text()
for old, new in [
    ('Test Outlook message with attachments', 'Plans for the spring gathering'),
    ('This is a <strong>synthetic</strong> Outlook <code>.msg</code> test fixture.', 'The spring gathering is coming together beautifully.'),
    ('It ships with a PDF attachment and an inline 1x1 PNG:', 'I have attached the agenda for our planning session.'),
]:
    source = source.replace(old, new)
namespace = {'__name__': 'demo_msg'}
exec(compile(source, 'gen-sample-msg.py', 'exec'), namespace)
original_assign = namespace['assign_dir_indices']
roots = []
def capture_root(root):
    roots.append(root)
    return original_assign(root)
namespace['assign_dir_indices'] = capture_root
namespace['main'](str(OUT / 'outlook.msg'))
namespace['assign_dir_indices'] = original_assign
root = roots[0]
attachment = next(node for node in root.children if node.name == '__attach_version1.0_#00000000')
next(node for node in attachment.children if node.name == '__substg1.0_37010102').payload = pdf_data
node = namespace['StorageNode']
extra = root.add(node('__attach_version1.0_#00000002', namespace['OBJ_STORAGE']))
for tag, value in [('3704001F', 'budget.xlsx'), ('3707001F', 'budget.xlsx'), ('370E001F', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')]:
    extra.add(node('__substg1.0_' + tag, namespace['OBJ_STREAM'])).payload = value.encode('utf-16-le')
extra.add(node('__substg1.0_37010102', namespace['OBJ_STREAM'])).payload = xlsx_data
spec = importlib.util.spec_from_file_location('large_msg', ROOT / 'Scripts/appstore/large-msg.py')
large_msg = importlib.util.module_from_spec(spec)
spec.loader.exec_module(large_msg)
large_msg.write_message(namespace, root, OUT / 'outlook.msg')
